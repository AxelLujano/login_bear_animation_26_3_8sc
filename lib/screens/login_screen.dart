import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  //Control para mostrar u ocultar la contraseña
  bool _obscure = true;
  @override
  Widget build(BuildContext context) {
    //Para obtener el tamaño de la pantalla
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
                width: size.width,
                height: 200,
                child: RiveAnimation.asset('login-bear.riv'),
              ),
              //Sizedbox para separar espacios
              SizedBox(height: 10),
              //Campo de texto para el correo
              TextField(
                //para mostrar el tipo de teclado
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border:OutlineInputBorder(
                    //Redondeo de bordes
                    borderRadius: BorderRadius.circular(12),
                  )
                ),
              ),
              SizedBox(height: 10),
              //Campo de texto para la contraseña
              TextField(
                obscureText: _obscure,
                //para mostrar el tipo de teclado
                decoration: InputDecoration(
                  hintText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  //Operador ternario
                  suffixIcon: IconButton(
                    //If ternario
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      //Refrescar el estado del widget
                      setState(() {
                        _obscure = !_obscure;
                      });
                    },
                  ),
                  border:OutlineInputBorder(
                    //Redondeo de bordes
                    borderRadius: BorderRadius.circular(12),
                  )
                ),
              ),
            ]
          ),
          ),
        ),
      );
  }
}