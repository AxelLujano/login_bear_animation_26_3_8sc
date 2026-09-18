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

  //1.1 Crear el cerebro de la animacion
  StateMachineController? _controller;
  //SMT: State Machine Input / Entrada de maquina de estado
  SMIInput? _isChecking;
  SMIInput? _isHandsUp;
  SMIInput? _trigSuccess;
  SMIInput? _trigFail;

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
                child: RiveAnimation.asset(
                  'login-bear.riv',
                  stateMachines: ['Login Machine'],
                //1.2 Vincular Animacion
                onInit: (artboard) {
                  _controller = StateMachineController.fromArtboard(
                    artboard, 'Login Machine'
                    );

                    //1.3 Verificar que el controlador no sea nulo
                    if (_controller == null) return;
                    //Agrega el controlador al escenario/tablero
                    artboard.addController(_controller!);
                    //Vinculamos variables
                    _isChecking = _controller?.findSMI('isChecking');
                    _isHandsUp = _controller?.findSMI('isHandsUp');
                    _trigSuccess = _controller?.findSMI('trigSuccess');
                    _trigFail = _controller?.findSMI('trigFail');
                  },
                )
              ),
              //Sizedbox para separar espacios
              SizedBox(height: 10),
              //Campo de texto para el correo
              TextField(
                onChanged: (value){
                  if (_isHandsUp != null) {
                    //No tapes los ojos al ver email
                    _isHandsUp!.change(false);
                  }
                  //Si isChecking no es nulo, cambiar el valor de la variable
                  if (_isChecking != null) {
                    //Activar modo chismoso
                    _isChecking!.change(true);
                  }
                },
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
                  onChanged: (value){
                  if (_isChecking != null) {
                    //No tapes los ojos al ver email
                    _isChecking !.change(false);
                  }
                  //Si isChecking no es nulo, cambiar el valor de la variable
                  if (_isHandsUp != null) {
                    //Activar modo chismoso
                    _isHandsUp!.change(true);
                  }
                },
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