/// Roles are stored as strings in Firestore and must be mirrored by Firebase
/// custom claims for privileged server-side operations.
enum UserRole {
  learner, jobSeeker, employee, mentor, instructor, employer, recruiter,
  agency, institution, companyAdmin, platformAdmin;

  String get value => switch (this) {
        UserRole.jobSeeker => 'job_seeker',
        UserRole.companyAdmin => 'company_admin',
        UserRole.platformAdmin => 'platform_admin',
        _ => name,
      };

  static UserRole fromValue(String? value) => switch (value) {
        'job_seeker' => UserRole.jobSeeker,
        'company_admin' => UserRole.companyAdmin,
        'platform_admin' => UserRole.platformAdmin,
        'employee' => UserRole.employee,
        'mentor' => UserRole.mentor,
        'instructor' => UserRole.instructor,
        'employer' => UserRole.employer,
        'recruiter' => UserRole.recruiter,
        'agency' => UserRole.agency,
        'institution' => UserRole.institution,
        _ => UserRole.learner,
      };
}

enum WorkspaceKind { learner, company, administration }

extension UserRoleWorkspace on UserRole {
  bool get canUseLearnerWorkspace => switch (this) {
        UserRole.learner || UserRole.jobSeeker || UserRole.employee ||
        UserRole.mentor || UserRole.instructor => true,
        _ => false,
      };
  bool get canUseCompanyWorkspace => switch (this) {
        UserRole.employer || UserRole.recruiter || UserRole.agency ||
        UserRole.institution || UserRole.companyAdmin => true,
        _ => false,
      };
  bool get canUseAdministration => this == UserRole.platformAdmin;
}
