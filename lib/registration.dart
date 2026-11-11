import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:team_project/dashboard.dart';
import 'main.dart';

// Palette shared with the login screen.
const _ink = Color(0xFF14213D);
const _teal = Color(0xFF1F7A8C);
const _red = Color(0xFFD62828);
const _cream = Color(0xFFFFF8E1);
const _background = Color(0xFFFFF6CC);

class Registration extends StatefulWidget {
  const Registration({Key? key}) : super(key: key);

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  Map userData = {};
  final _formkey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create an Account', style: TextStyle(color: _cream, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFFF5A623),
      ),
      backgroundColor: _background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Form(
            key: _formkey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Center(
                    child: Container(
                      width: 200,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: _teal),
                      ),
                      //child: ,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextFormField(
                    // validator: ((value) {
                    //   if (value == null || value.isEmpty) {
                    //     return 'please enter some text';
                    //   } else if (value.length < 5) {
                    //     return 'Enter atleast 5 Charecter';
                    //   }

                    //   return null;
                    // }),
                    /*validator: MultiValidator([
                          RequiredValidator(errorText: 'Enter first named'),
                          MinLengthValidator(3,
                              errorText: 'Minimum 3 charecter filled name'),
                        ]),*/
                    decoration: InputDecoration(
                      hintText: 'Enter first Name',
                      labelText: 'First Name',
                      prefixIcon: Icon(Icons.person, color: _red),
                      errorStyle: TextStyle(fontSize: 18.0),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: _red),
                        borderRadius: BorderRadius.all(Radius.circular(9.0)),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    /*validator: MultiValidator([
                          RequiredValidator(errorText: 'Enter last named'),
                          MinLengthValidator(3,
                              errorText:
                              'Last name should be atleast 3 charater'),
                        ]),*/
                    decoration: InputDecoration(
                      hintText: 'Enter last Name',
                      labelText: 'Last Name',
                      prefixIcon: Icon(Icons.person, color: _red),
                      errorStyle: TextStyle(fontSize: 18.0),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.all(Radius.circular(9.0)),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    /*validator: MultiValidator([
                          RequiredValidator(errorText: 'Enter email address'),
                          EmailValidator(
                              errorText: 'Please correct email filled'),
                        ]),*/
                    decoration: InputDecoration(
                      hintText: 'abc@example.com',
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email, color: _red),
                      errorStyle: TextStyle(fontSize: 18.0),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.all(Radius.circular(9.0)),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    /* validator: MultiValidator([
                          RequiredValidator(errorText: 'Enter mobile number'),
                          PatternValidator(r'(^[0,9]{10}$)',
                              errorText: 'enter vaid mobile number'),
                        ]),*/
                    decoration: InputDecoration(
                      hintText: '5145553434',
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone, color: _red),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.all(Radius.circular(9)),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 50,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const HomePage()));
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Color(0xFFF5A623),
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Register'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
