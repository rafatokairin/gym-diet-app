package com.rafalift.spring_project.repository;

import com.rafalift.spring_project.model.Users;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Repository;

@Repository
public interface UsersRepository extends JpaRepository<Users, Integer> {
    UserDetails findByEmail(String email);
    boolean existsByEmail(String email);
}
