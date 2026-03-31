package MediLeave.MediLeave.repository;



import MediLeave.MediLeave.entity.Role;
import MediLeave.MediLeave.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
    boolean existsByRegistrationNo(String registrationNo);
    List<User> findByRole(Role role);
    boolean existsByRole(Role role);
}