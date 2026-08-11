/// The two account types supported by the app.
enum UserRole {
  driver('I am a Driver', 'Request emergency help'),
  mechanic('I am a Mechanic', 'Provide assistance');

  const UserRole(this.title, this.subtitle);

  final String title;
  final String subtitle;
}
