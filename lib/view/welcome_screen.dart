import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../registration_page.dart';
import '../widget/bg_container.dart';
import '../widget/button.dart';
import 'google_signIn.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);

    return Scaffold(
      body: BackgroundContainer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image.asset(
            //   'assets/tic_tac_toe.png',
            //   width: 300,
            //   height: 100,
            // ),
            Image.asset(
              'assets/icon/icon.png',
              width: 300.w,
              height: 300.h,
            ),
            SizedBox(height: 40),
            AppButton(
              label: 'Login',
              // backgroundColor: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => LoginScreen(isRegistration: false)),
                );
              },
            ),
            SizedBox(height: 20),
            AppButton(
              label: 'Registration',
              // backgroundColor: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  // MaterialPageRoute(builder: (context) => LoginScreen(isRegistration:true)),
                  MaterialPageRoute(builder: (context) => RegistrationScreen()),
                );
              },
            ),


          ],
        ),
      ),
    );
  }
}
