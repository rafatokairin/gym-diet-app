package com.rafalift.spring_project.security;

import com.rafalift.spring_project.model.Users;
import com.rafalift.spring_project.repository.UsersRepository;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

@Component
public class UsersUtils {

    private final UsersRepository usersRepository;

    public UsersUtils(UsersRepository usersRepository) {
        this.usersRepository = usersRepository;
    }

    public Integer getCurrentUserId() {
        var authentication = SecurityContextHolder.getContext().getAuthentication();
        var userDetails = (UserDetails) authentication.getPrincipal();
        Users user = (Users) usersRepository.findByEmail(userDetails.getUsername());
        return user.getId();
    }

    public Users getCurrentUser() {
        var authentication = SecurityContextHolder.getContext().getAuthentication();
        var userDetails = (UserDetails) authentication.getPrincipal();
        return (Users) usersRepository.findByEmail(userDetails.getUsername());
    }
}
