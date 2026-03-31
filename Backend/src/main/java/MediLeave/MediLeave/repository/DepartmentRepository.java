package MediLeave.MediLeave.repository;


import MediLeave.MediLeave.entity.Department;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DepartmentRepository extends JpaRepository<Department, Long> {
}