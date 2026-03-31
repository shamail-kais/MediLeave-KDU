package MediLeave.MediLeave.dto;


import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class AuthResponse {
    private String token;
    private Long userId;
    private String fullName;
    private String email;
    private String role;
}