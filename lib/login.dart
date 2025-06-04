import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _signUpEmailController = TextEditingController();
  final TextEditingController _signUpPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _passwordVisible = false;
  bool _signUpPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[400],
        title: Text(
          'Bio-AMP',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        leading: InkWell(
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onDoubleTap: () {},
          child: Hero(
            tag: 'imageTag1',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: Image.asset(
                'assets/images/mmne_logo.png',
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        actions: [
          ClipRRect(
            borderRadius: BorderRadius.circular(0),
            child: Image.asset(
              'assets/images/BITS_Pilani-Logo.png',
              width: 60,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            indicatorColor: Colors.green,
            tabs: [
              Tab(text: 'Sign In'),
              Tab(text: 'Sign Up'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSignInTab(),
                _buildSignUpTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(40)),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: !_passwordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(40)),
              suffixIcon: IconButton(
                icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _passwordVisible = !_passwordVisible;
                  });
                },
              ),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            ),
            child: Text('Sign In'),
          ),
          SizedBox(height: 10),
          TextButton(
            onPressed: () {},
            child: Text('Forgot Password?'),
          ),
          SizedBox(height: 20),
          _buildSocialLoginButtons(),
        ],
      ),
    );
  }

  Widget _buildSignUpTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _signUpEmailController,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(40)),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _signUpPasswordController,
            obscureText: !_signUpPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(40)),
              suffixIcon: IconButton(
                icon: Icon(_signUpPasswordVisible ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _signUpPasswordVisible = !_signUpPasswordVisible;
                  });
                },
              ),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController,
            obscureText: !_confirmPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(40)),
              suffixIcon: IconButton(
                icon: Icon(_confirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _confirmPasswordVisible = !_confirmPasswordVisible;
                  });
                },
              ),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            ),
            child: Text('Sign Up'),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLoginButtons() {
    return Column(
      children: [
        Text('Or sign in with'),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: FaIcon(FontAwesomeIcons.google),
              onPressed: () {},
            ),
            SizedBox(width: 20),
            IconButton(
              icon: FaIcon(FontAwesomeIcons.apple),
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}
