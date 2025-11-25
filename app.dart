import 'package:flutter/material.dart';

void main() {
	runApp(NexoraApp());
}

class NexoraApp extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			title: 'Nexora',
			theme: ThemeData(primarySwatch: Colors.blue),
			home: LoadingPage(),
			routes: {
				'/signup': (context) => SignUpPage(),
				'/info': (context) => InfoPage(),
				'/home': (context) => HomePage(),
				'/settings': (context) => SettingsPage(),
				'/studentinfo': (context) => StudentInfoPage(),
				'/fbla': (context) => FBLAInfoPage(),
				'/events': (context) => FBLAEventsPage(),
				'/calendar': (context) => CalendarPage(),
				'/social': (context) => SocialMediaPage(),
				'/news': (context) => NewsFeedPage(),
			},
		);
	}
}

class LoadingPage extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		Future.delayed(Duration(seconds: 2), () {
			Navigator.pushReplacementNamed(context, '/signup');
		});
		return Scaffold(
			body: Center(child: CircularProgressIndicator()),
		);
	}
}

class SignUpPage extends StatelessWidget {
	final _formKey = GlobalKey<FormState>();
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: Text('Sign Up')),
			body: Padding(
				padding: const EdgeInsets.all(16.0),
				child: Form(
					key: _formKey,
					child: Column(
						children: [
							TextFormField(decoration: InputDecoration(labelText: 'Email')),
							TextFormField(decoration: InputDecoration(labelText: 'Username')),
							TextFormField(decoration: InputDecoration(labelText: 'Password'), obscureText: true),
							SizedBox(height: 20),
							ElevatedButton(
								onPressed: () {
									Navigator.pushReplacementNamed(context, '/info');
								},
								child: Text('Next'),
							),
						],
					),
				),
			),
		);
	}
}

class InfoPage extends StatelessWidget {
	final _formKey = GlobalKey<FormState>();
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: Text('Information')),
			body: Padding(
				padding: const EdgeInsets.all(16.0),
				child: Form(
					key: _formKey,
					child: ListView(
						children: [
							TextFormField(decoration: InputDecoration(labelText: 'First Name')),
							TextFormField(decoration: InputDecoration(labelText: 'Last Name')),
							TextFormField(decoration: InputDecoration(labelText: 'School')),
							TextFormField(decoration: InputDecoration(labelText: 'Age')),
							TextFormField(decoration: InputDecoration(labelText: 'Grade')),
							TextFormField(decoration: InputDecoration(labelText: 'Address')),
							SizedBox(height: 20),
							ElevatedButton(
								onPressed: () {
									Navigator.pushReplacementNamed(context, '/home');
								},
								child: Text('Submit'),
							),
						],
					),
				),
			),
		);
	}
}

class HomePage extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: Row(
					children: [
						FlutterLogo(),
						SizedBox(width: 10),
						Text('Nexora'),
					],
				),
			),
			drawer: AppDrawer(),
			body: Center(child: Text('Welcome to Nexora!')),
		);
	}
}

class AppDrawer extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		return Drawer(
			child: ListView(
				padding: EdgeInsets.zero,
				children: [
					DrawerHeader(
						decoration: BoxDecoration(color: Colors.blue),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								FlutterLogo(size: 48),
								SizedBox(height: 10),
								Text('Nexora', style: TextStyle(color: Colors.white, fontSize: 24)),
							],
						),
					),
					ListTile(
						leading: Icon(Icons.home),
						title: Text('Home'),
						onTap: () => Navigator.pushReplacementNamed(context, '/home'),
					),
					ListTile(
						leading: Icon(Icons.person),
						title: Text('Student Info'),
						onTap: () => Navigator.pushReplacementNamed(context, '/studentinfo'),
					),
					ListTile(
						leading: Icon(Icons.settings),
						title: Text('Settings'),
						onTap: () => Navigator.pushReplacementNamed(context, '/settings'),
					),
					ListTile(
						leading: Icon(Icons.info),
						title: Text('FBLA Info'),
						onTap: () => Navigator.pushReplacementNamed(context, '/fbla'),
					),
					ListTile(
						leading: Icon(Icons.event),
						title: Text('FBLA Events'),
						onTap: () => Navigator.pushReplacementNamed(context, '/events'),
					),
					ListTile(
						leading: Icon(Icons.calendar_today),
						title: Text('Calendar'),
						onTap: () => Navigator.pushReplacementNamed(context, '/calendar'),
					),
					ListTile(
						leading: Icon(Icons.link),
						title: Text('FBLA Social Media'),
						onTap: () => Navigator.pushReplacementNamed(context, '/social'),
					),
					ListTile(
						leading: Icon(Icons.announcement),
						title: Text('News Feed'),
						onTap: () => Navigator.pushReplacementNamed(context, '/news'),
					),
				],
			),
		);
	}
}

class SettingsPage extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: Text('Settings')),
			drawer: AppDrawer(),
			body: ListView(
				children: [
					ListTile(title: Text('Edit Profile'), leading: Icon(Icons.edit)),
					ListTile(title: Text('Sign Out'), leading: Icon(Icons.logout)),
					ListTile(title: Text('Help'), leading: Icon(Icons.help)),
					ListTile(title: Text('Terms and Policies'), leading: Icon(Icons.policy)),
					ListTile(title: Text('Notifications'), leading: Icon(Icons.notifications)),
				],
			),
		);
	}
}

class StudentInfoPage extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: Text('Student Info')),
			drawer: AppDrawer(),
			body: ListView(
				children: [
					ListTile(title: Text('Classes')),
					ListTile(title: Text('Activities')),
					ListTile(title: Text('Clubs')),
					ListTile(title: Text('GPA')),
					ListTile(title: Text('SAT/ACT')),
					ListTile(title: Text('Volunteering')),
				],
			),
		);
	}
}

class FBLAInfoPage extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: Text('FBLA Info')),
			drawer: AppDrawer(),
			body: Center(child: Text('FBLA Information Page')),
		);
	}
}

class FBLAEventsPage extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: Text('FBLA Events')),
			drawer: AppDrawer(),
			body: Center(child: Text('FBLA Events Page')),
		);
	}
}

class CalendarPage extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: Text('Calendar')),
			drawer: AppDrawer(),
			body: Center(child: Text('Calendar Page')),
		);
	}
}

class SocialMediaPage extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: Text('FBLA Social Media')),
			drawer: AppDrawer(),
			body: Center(child: Text('FBLA Social Media Links')),
		);
	}
}

class NewsFeedPage extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: Text('News Feed')),
			drawer: AppDrawer(),
			body: Center(child: Text('News Feed with Announcements')),
		);
	}
}
