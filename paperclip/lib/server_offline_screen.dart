import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'main.dart';

class ServerOfflineScreen extends StatelessWidget {
  const ServerOfflineScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.08,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: size.height * 0.3,
                    child: Lottie.asset(
                      'assets/animations/server_offline.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                  
                  SizedBox(height: size.height * 0.01),
                  
                  const Text(
                    'Server Offline',
                    style: TextStyle(
                      color: Color(0xFF7B4EFF),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  
                  SizedBox(height: size.height * 0.01),
                  
                  const Text(
                    "The server is only active during TSHS' Quarterly Examination Schedule!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  
                  SizedBox(height: size.height * 0.03),
                  
                  SizedBox(
                    width: size.width * 0.5,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: const Color(0xFF7B4EFF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'View Schedule',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}