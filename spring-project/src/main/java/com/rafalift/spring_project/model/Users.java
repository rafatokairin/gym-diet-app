package com.rafalift.spring_project.model;

import jakarta.persistence.*;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;

import java.sql.Date;
import java.util.Collection;
import java.util.List;

@Entity
@Table(name = "users")
public class Users implements UserDetails {
    public Users() {}

    @Override
    public String getUsername() {
        return email;
    }

    @Override
    public String getPassword() {
        return senha;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        if (this.role == UserRole.ADMIN)
            return List.of(new SimpleGrantedAuthority("ROLE_ADMIN"), new SimpleGrantedAuthority("ROLE_USER"));
        else
            return List.of(new SimpleGrantedAuthority("ROLE_USER"));
    }

    @Override
    public boolean isEnabled() {
        return true; // Conta sempre ativa (pode personalizar)
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true; // Credenciais nunca expiram (pode personalizar)
    }

    @Override
    public boolean isAccountNonLocked() {
        return true; // Conta nunca é bloqueada (pode personalizar)
    }

    @Override
    public boolean isAccountNonExpired() {
        return true; // Credenciais nunca expiram (pode personalizar)
    }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;
    private String nome;
    private String email;
    private String senha;
    private Date data_reg;
    private Date data_att;
    private UserRole role;

    public Users(String nome, String email, String senha, UserRole role) {
        this.nome = nome;
        this.email = email;
        this.senha = senha;
        this.role = role;
    }

    public UserRole getRole() {
        return role;
    }

    public void setRole(UserRole role) {
        this.role = role;
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getNome() {
        return nome;
    }

    public void setNome(String nome) {
        this.nome = nome;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getSenha() {
        return senha;
    }

    public void setSenha(String senha) {
        this.senha = senha;
    }

    public Date getData_reg() {
        return data_reg;
    }

    public void setData_reg(Date data_reg) {
        this.data_reg = data_reg;
    }

    public Date getData_att() {
        return data_att;
    }

    public void setData_att(Date data_att) {
        this.data_att = data_att;
    }
}