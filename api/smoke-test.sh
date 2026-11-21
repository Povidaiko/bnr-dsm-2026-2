#!/usr/bin/env bash
# Teste de fumaça do Trabalho 1: percorre todos os cenários exigidos no PDF,
# confere o status HTTP esperado e apaga tudo o que criou no final.
# Uso:  ./smoke-test.sh            (API em http://localhost:8888)
#       BASE_URL=http://host:porta ./smoke-test.sh
# Os PRINTS oficiais devem ser feitos no EchoAPI Client, não aqui.

BASE_URL="${BASE_URL:-http://localhost:8888}"
PASS=0; FAIL=0; STATUS=""; BODY=""

call() { # rótulo status_esperado método caminho [corpo]
  local label="$1" expected="$2" method="$3" path="$4" body="${5:-}" out
  if [ -n "$body" ]; then
    out=$(curl -s -w $'\n%{http_code}' -X "$method" "$BASE_URL$path" -H 'Content-Type: application/json' -d "$body")
  else
    out=$(curl -s -w $'\n%{http_code}' -X "$method" "$BASE_URL$path")
  fi
  STATUS="${out##*$'\n'}"; BODY="${out%$'\n'*}"
  if [ "$STATUS" = "$expected" ]; then PASS=$((PASS+1)); printf '  [ OK ] %-52s %s\n' "$label" "$STATUS"
  else FAIL=$((FAIL+1)); printf '  [FAIL] %-52s esperado %s, veio %s\n         %s\n' "$label" "$expected" "$STATUS" "${BODY:0:300}"; fi
}
has() { # rótulo trecho_esperado_no_corpo_da_última_resposta
  if printf '%s' "$BODY" | grep -q -- "$2"; then PASS=$((PASS+1)); printf '  [ OK ] %s\n' "$1"
  else FAIL=$((FAIL+1)); printf '  [FAIL] %s (não encontrei: %s)\n' "$1" "$2"; fi
}
id_of() { printf '%s' "$BODY" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4; }

end='[{"logradouro":"Rua A","numero":"1","municipio":"Franca","uf":"SP","cep":"14400-000"},{"logradouro":"Rua B","numero":"2","municipio":"Franca","uf":"SP","cep":"14400-100"}]'
aluno() { printf '{"nome":"%s","cpf":"%s","telefone":"16999990000","email":"%s","enderecos":%s}' "$1" "$2" "$3" "$end"; }
turma() { printf '{"cursoId":"%s","instrutorId":"%s","dataInicio":"%s","dataFim":"%s","numVagas":%s,"status":"%s","horarios":[{"diaSemana":"SEGUNDA","inicio":"19:00","fim":"22:30"}]}' "$CURSO" "$INSTR" "$1" "$2" "$3" "$4"; }
mat()   { printf '{"alunoId":"%s","turmaId":"%s","status":"%s","notas":[{"avaliacao":"P1","valor":8.5}]}' "$1" "$2" "$3"; }

echo "== API em $BASE_URL"
call "GET /" 200 GET /

echo "== Preparação"
call "Criar curso" 201 POST /cursos '{"nome":"Curso Teste","cargaHoraria":"80 horas","valor":1500.0,"modulos":[{"titulo":"M1","conteudo":"C1","cargaHoraria":"20 horas"}]}'; CURSO=$(id_of)
call "Criar instrutor" 201 POST /instrutores '{"nome":"Instrutor Teste","cpf":"12345678909","email":"i@example.com","valorHoraAula":"80.00","especialidades":["Java"],"enderecos":[]}'; INSTR=$(id_of)

echo "== 3. Alunos"
call "3a criar aluno (2 endereços)" 201 POST /alunos "$(aluno 'Aluno Teste Um' 11144477735 a1@example.com)"; A1=$(id_of)
call "3b aluno inválido -> 400" 400 POST /alunos '{"nome":"","cpf":"123","telefone":"","email":"abc"}'
has "3b lista mensagens de validação" 'obrigat'
call "criar 2º aluno" 201 POST /alunos "$(aluno 'Aluno Teste Dois' 52998224725 a2@example.com)"; A2=$(id_of)
call "criar 3º aluno (para excluir)" 201 POST /alunos "$(aluno 'Aluno Teste Tres' 39053344705 a3@example.com)"; A3=$(id_of)
call "3c listar alunos" 200 GET /alunos
call "3d atualizar aluno" 200 PUT "/alunos/$A1" "$(aluno 'Aluno Teste Um Editado' 11144477735 a1@example.com)"
echo "== 3b (extra): validação do endereço aninhado"
call "aluno com endereço sem logradouro -> 400" 400 POST /alunos '{"nome":"X","cpf":"11144477735","telefone":"1","email":"x@x.com","enderecos":[{"numero":"1"}]}'

echo "== 5. Turmas"
call "criar turma 1" 201 POST /turmas "$(turma 2026-12-01 2027-03-01 30 PREVISTA)"; T1=$(id_of)
call "criar turma 2" 201 POST /turmas "$(turma 2027-03-15 2027-06-15 25 PREVISTA)"; T2=$(id_of)
call "criar turma 3 (para excluir)" 201 POST /turmas "$(turma 2027-07-01 2027-09-30 20 PREVISTA)"; T3=$(id_of)
call "5b turma inválida -> 400" 400 POST /turmas "{\"cursoId\":\"$CURSO\",\"instrutorId\":\"$INSTR\",\"dataFim\":\"2027-01-01\",\"numVagas\":0,\"status\":\"XYZ\"}"
call "5c listar turmas" 200 GET /turmas
has "5c traz curso completo" '"curso":{'
has "5c traz instrutor completo" '"instrutor":{'
call "GET turma 1 (confere dataInicio)" 200 GET "/turmas/$T1"
has "dataInicio correta (não repetiu dataFim)" '"dataInicio":"2026-12-01"'
call "5d atualizar turma" 200 PUT "/turmas/$T1" "$(turma 2026-12-01 2027-03-10 35 ATIVA)"

echo "== 4. Matrículas"
call "4a criar matrícula" 201 POST /matriculas "$(mat "$A1" "$T1" ABERTA)"; M1=$(id_of)
call "criar matrícula 2" 201 POST /matriculas "$(mat "$A2" "$T1" ABERTA)"; M2=$(id_of)
call "criar matrícula 3 (para excluir)" 201 POST /matriculas "$(mat "$A1" "$T2" ABERTA)"; M3=$(id_of)
call "4b matrícula inválida -> 400" 400 POST /matriculas "$(mat "$A1" "$T1" INVALIDO)"
call "matrícula duplicada -> 400" 400 POST /matriculas "$(mat "$A1" "$T1" ABERTA)"
call "4c listar matrículas" 200 GET /matriculas
has "4c traz aluno completo" '"aluno":{'
has "4c traz turma completa" '"turma":{'
call "4d atualizar matrícula" 200 PUT "/matriculas/$M1" "$(mat "$A1" "$T1" FECHADA)"

echo "== Exclusões com 409"
call "3f excluir aluno COM matrícula -> 409" 409 DELETE "/alunos/$A1"
call "5f excluir turma COM matrícula -> 409" 409 DELETE "/turmas/$T1"

echo "== 6. Listagens extras"
call "6a matrículas do aluno" 200 GET "/matriculas/aluno/$A1"
call "6b matrículas do curso" 200 GET "/matriculas/curso/$CURSO"
call "6c turmas do curso" 200 GET "/turmas/curso/$CURSO"

echo "== Exclusões com 204"
call "4e excluir matrícula" 204 DELETE "/matriculas/$M3"
call "3e excluir aluno SEM matrícula" 204 DELETE "/alunos/$A3"
call "5e excluir turma SEM matrícula" 204 DELETE "/turmas/$T3"

echo "== Limpeza"
call "excluir matrícula 1" 204 DELETE "/matriculas/$M1"
call "excluir matrícula 2" 204 DELETE "/matriculas/$M2"
call "excluir aluno 1" 204 DELETE "/alunos/$A1"
call "excluir aluno 2" 204 DELETE "/alunos/$A2"
call "excluir turma 1" 204 DELETE "/turmas/$T1"
call "excluir turma 2" 204 DELETE "/turmas/$T2"
call "excluir curso" 204 DELETE "/cursos/$CURSO"
call "excluir instrutor" 204 DELETE "/instrutores/$INSTR"

echo; echo "Resultado: $PASS ok, $FAIL falhas"
[ "$FAIL" -eq 0 ]
