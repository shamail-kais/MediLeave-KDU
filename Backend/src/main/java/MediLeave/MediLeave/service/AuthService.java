package MediLeave.MediLeave.service;

import MediLeave.MediLeave.config.JwtUtil;
import MediLeave.MediLeave.dto.AuthResponse;
import MediLeave.MediLeave.dto.LoginRequest;
import MediLeave.MediLeave.dto.RegisterRequest;
import MediLeave.MediLeave.entity.Department;
import MediLeave.MediLeave.entity.Role;
import MediLeave.MediLeave.entity.User;
import MediLeave.MediLeave.exception.ApiException;
import MediLeave.MediLeave.repository.DepartmentRepository;
import MediLeave.MediLeave.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final DepartmentRepository departmentRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public void registerStudent(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new ApiException("Email already registered");
        }
        if (userRepository.existsByRegistrationNo(request.getRegistrationNo())) {
            throw new ApiException("Registration number already exists");
        }

        Department department = departmentRepository.findById(request.getDepartmentId())
                .orElseThrow(() -> new ApiException("Department not found"));

        User user = User.builder()
                .fullName(request.getFullName())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .registrationNo(request.getRegistrationNo())
                .role(Role.ROLE_STUDENT)
                .department(department)
                .build();

        userRepository.save(user);
    }

    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new ApiException("Invalid email or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new ApiException("Invalid email or password");
        }

        String token = jwtUtil.generateToken(user.getId(), user.getEmail(), user.getRole());

        return AuthResponse.builder()
                .token(token)
                .userId(user.getId())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .role(user.getRole().name())
                .build();
    }
}