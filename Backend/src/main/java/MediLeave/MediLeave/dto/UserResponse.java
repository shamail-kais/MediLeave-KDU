package MediLeave.MediLeave.dto;


import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class UserResponse {
    private Long id;
    private String fullName;
    private String email;
    private String registrationNo;
    private String role;
    private String departmentName;
    private String faculty;
}
