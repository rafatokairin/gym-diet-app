package com.rafalift.spring_project.model;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.persistence.*;

import java.time.LocalTime;

@Entity
@Table(name = "foods")
public class Foods {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "diet_id", nullable = false)
    private UserDiets diet;

    private String tipo_alimento;
    private String alimento;
    private Integer peso;
    private Integer carboidratos;
    private Integer proteinas;
    private Integer fibras;
    private Integer gorduras;
    private Integer calorias;
    private String anotacao;
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "HH:mm")
    private LocalTime horario;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public UserDiets getDiet() {
        return diet;
    }

    public void setDiet(UserDiets diet) {
        this.diet = diet;
    }

    public String getAlimento() {
        return alimento;
    }

    public void setAlimento(String alimento) {
        this.alimento = alimento;
    }

    public Integer getPeso() {
        return peso;
    }

    public void setPeso(Integer peso) {
        this.peso = peso;
    }

    public Integer getCarboidratos() {
        return carboidratos;
    }

    public void setCarboidratos(Integer carboidratos) {
        this.carboidratos = carboidratos;
    }

    public Integer getProteinas() {
        return proteinas;
    }

    public void setProteinas(Integer proteinas) {
        this.proteinas = proteinas;
    }

    public Integer getFibras() {
        return fibras;
    }

    public void setFibras(Integer fibras) {
        this.fibras = fibras;
    }

    public Integer getGorduras() {
        return gorduras;
    }

    public void setGorduras(Integer gorduras) {
        this.gorduras = gorduras;
    }

    public Integer getCalorias() {
        return calorias;
    }

    public void setCalorias(Integer calorias) {
        this.calorias = calorias;
    }

    public String getTipo_alimento() {
        return tipo_alimento;
    }

    public void setTipo_alimento(String tipo_alimento) {
        this.tipo_alimento = tipo_alimento;
    }

    public String getAnotacao() {
        return anotacao;
    }

    public void setAnotacao(String anotacao) {
        this.anotacao = anotacao;
    }

    public LocalTime getHorario() {
        return horario;
    }

    public void setHorario(LocalTime horario) {
        this.horario = horario;
    }
}