package MediLeave.MediLeave.service;

import MediLeave.MediLeave.dto.CreateDepartmentRequest;
import MediLeave.MediLeave.dto.CreateStaffRequest;
import MediLeave.MediLeave.dto.UserResponse;
import MediLeave.MediLeave.entity.*;
import MediLeave.MediLeave.exception.ApiException;
import MediLeave.MediLeave.repository.DepartmentRepository;
import MediLeave.MediLeave.repository.LeaveRequestRepository;
import MediLeave.MediLeave.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final UserRepository userRepository;
    private final DepartmentRepository departmentRepository;
    private final LeaveRequestRepository leaveRequestRepository;
    private final PasswordEncoder passwordEncoder;

    public Department createDepartment(CreateDepartmentRequest request) {
        Department department = Department.builder()
                .name(request.getName())
                .faculty(request.getFaculty())
                .build();

        return departmentRepository.save(department);
    }

    public List<Department> getAllDepartments() {
        return departmentRepository.findAll();
    }

    public void createStaff(CreateStaffRequest request) {
        if (request.getRole() == Role.ROLE_STUDENT) {
            throw new ApiException("Admin endpoint cannot create student here");
        }

        if (userRepository.existsByEmail(request.getEmail())) {
            throw new ApiException("Email already exists");
        }

        Department department = departmentRepository.findById(request.getDepartmentId())
                .orElseThrow(() -> new ApiException("Department not found"));

        User user = User.builder()
                .fullName(request.getFullName())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .role(request.getRole())
                .department(department)
                .build();

        userRepository.save(user);
    }

    public List<UserResponse> getAllUsers() {
        return userRepository.findAll().stream().map(user -> UserResponse.builder()
                .id(user.getId())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .registrationNo(user.getRegistrationNo())
                .role(user.getRole().name())
                .departmentName(user.getDepartment() != null ? user.getDepartment().getName() : null)
                .faculty(user.getDepartment() != null ? user.getDepartment().getFaculty() : null)
                .build()).toList();
    }

    public List<LeaveRequest> getAllRequests() {
        return leaveRequestRepository.findAll();
    }
}