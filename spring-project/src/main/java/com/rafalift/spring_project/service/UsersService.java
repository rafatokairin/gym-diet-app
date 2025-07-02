package com.rafalift.spring_project.service;

import com.rafalift.spring_project.model.Users;
import com.rafalift.spring_project.repository.UsersRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class UsersService {
    private UsersRepository usersRepository;
    public UsersService(UsersRepository usersRepository) {
        this.usersRepository = usersRepository;
    }

    public List<Users> findAll() {
        return usersRepository.findAll();
    }

    public Users create(Users user) {
        return usersRepository.save(user);
    }

    public Users findById(Integer id) {
        return usersRepository.findById(id).orElseThrow(() -> new RuntimeException("User not found"));
    }

    public Users updateById(Integer id, Users userDetails) {
        Users user = findById(id);
        if (user != null) {
            user.setNome(userDetails.getNome());
            user.setEmail(userDetails.getEmail());
            return usersRepository.save(user);
        }
        return null;
    }

    public void deleteById(Integer id) {
        Users user = findById(id);
        usersRepository.deleteById(user.getId());
    }
}
