package MediLeave.MediLeave.config;

import MediLeave.MediLeave.entity.Role;
import MediLeave.MediLeave.entity.User;
import MediLeave.MediLeave.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {

        if (!userRepository.existsByRole(Role.ROLE_ADMIN)) {

            userRepository.save(
                    User.builder()
                            .fullName("System Admin")
                            .email("admin@medileave.com")
                            .password(passwordEncoder.encode("admin123"))
                            .role(Role.ROLE_ADMIN)
                            .build()
            );
        }

        if (!userRepository.existsByRole(Role.ROLE_MEDICAL_OFFICER)) {

            userRepository.save(
                    User.builder()
                            .fullName("Medical Officer")
                            .email("medical@medileave.com")
                            .password(passwordEncoder.encode("medical123"))
                            .role(Role.ROLE_MEDICAL_OFFICER)
                            .build()
            );
        }

        if (!userRepository.existsByRole(Role.ROLE_DEPARTMENT_REVIEWER)) {

            userRepository.save(
                    User.builder()
                            .fullName("Department Reviewer")
                            .email("department@medileave.com")
                            .password(passwordEncoder.encode("department123"))
                            .role(Role.ROLE_DEPARTMENT_REVIEWER)
                            .build()
            );
        }

        System.out.println("Default system users initialized");
    }
}