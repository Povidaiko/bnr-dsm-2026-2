package br.edu.fatecfranca.api.models;


import java.util.List;


import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;


@Document(collection = "turmas")
public class Turma {


   @Id
   private String id;


   private String cursoId;
   private String instrutorId;
   private String dataInicio;
   private String dataFim;
   private Integer vagas;
   private String status;


   private List<Horario> horarios;


   public Turma() {
   }

   public Turma(
            String id,
            String cursoId,
            String instrutorId,
            String dataInicio,
            String dataFim,
            Integer vagas,
            String status,
            List<Horario> horarios) {
       this.id = id;
       this.cursoId = cursoId;
       this.instrutorId = instrutorId;
       this.dataInicio = dataInicio;
       this.dataFim = dataFim;
       this.vagas = vagas;
       this.status = status;
       this.horarios = horarios;
   }

   public String getId() {
    return id;
   }

   public void setId(String id) {
    this.id = id;
   }

   public String getCursoId() {
    return cursoId;
   }

   public void setCursoId(String cursoId) {
    this.cursoId = cursoId;
   }

   public String getInstrutorId() {
    return instrutorId;
   }

   public void setInstrutorId(String instrutorId) {
    this.instrutorId = instrutorId;
   }

   public String getDataInicio() {
    return dataInicio;
   }

   public void setDataInicio(String dataInicio) {
    this.dataInicio = dataInicio;
   }

   public String getDataFim() {
    return dataFim;
   }

   public void setDataFim(String dataFim) {
    this.dataFim = dataFim;
   }

   public Integer getVagas() {
    return vagas;
   }

   public void setVagas(Integer vagas) {
    this.vagas = vagas;
   }

   public String getStatus() {
    return status;
   }

   public void setStatus(String status) {
    this.status = status;
   }

   public List<Horario> getHorarios() {
    return horarios;
   }

   public void setHorarios(List<Horario> horarios) {
    this.horarios = horarios;
   }


   

   //*
}
