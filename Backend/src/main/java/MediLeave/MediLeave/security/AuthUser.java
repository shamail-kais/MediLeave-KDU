package MediLeave.MediLeave.security;


import MediLeave.MediLeave.entity.Role;
import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class AuthUser {
    private Long userId;
    private String email;
    private Role role;
}