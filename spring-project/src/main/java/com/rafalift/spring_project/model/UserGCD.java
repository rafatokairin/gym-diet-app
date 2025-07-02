package com.rafalift.spring_project.model;

import jakarta.persistence.*;

@Entity
@Table(name = "user_gcd")
public class UserGCD {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private Users user;

    private Integer carboidratos_gcd;
    private Integer proteinas_gcd;
    private Integer fibras_gcd;
    private Integer gorduras_gcd;
    private Integer gcd;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Users getUser() {
        return user;
    }

    public void setUser(Users user) {
        this.user = user;
    }

    public Integer getCarboidratos_gcd() {
        return carboidratos_gcd;
    }

    public void setCarboidratos_gcd(Integer carboidratos_gcd) {
        this.carboidratos_gcd = carboidratos_gcd;
    }

    public Integer getProteinas_gcd() {
        return proteinas_gcd;
    }

    public void setProteinas_gcd(Integer proteinas_gcd) {
        this.proteinas_gcd = proteinas_gcd;
    }

    public Integer getFibras_gcd() {
        return fibras_gcd;
    }

    public void setFibras_gcd(Integer fibras_gcd) {
        this.fibras_gcd = fibras_gcd;
    }

    public Integer getGorduras_gcd() {
        return gorduras_gcd;
    }

    public void setGorduras_gcd(Integer gorduras_gcd) {
        this.gorduras_gcd = gorduras_gcd;
    }

    public Integer getGcd() {
        return gcd;
    }

    public void setGcd(Integer gcd) {
        this.gcd = gcd;
    }
}
