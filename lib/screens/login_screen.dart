import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async'; //3.1 Importar el timer

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
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;

  //3.2 Variable del reccorido de la mirada
  SMINumber? _numLook;

  //3.3 Timer para detener la mirada al dejar de escribir
  Timer? _typingDebounce;

  //2.1 Crear las variables para FocusNode
  final _emailFocus = FocusNode(); //Se llama node por un foco de cosas que puede hacer
  final _passWordFocus = FocusNode();

  //4.1 Controllers que manipulan lo que el usuario escribe
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  //4.2 Errores para mostarlo en la UI(pantalla)
  String? emailError;
  String? passError;

  //4.3 Validar el email y la contraseña
  bool isValidEmail(String email) {
    //Expresion regular para validar el email
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    //Expresion regular para validar la contraseña
    final re = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',);
    return re.hasMatch(pass);
  }

  //4.4 Dar accion al boton de login
  void _onLogin(){
    //4.5 De lo que escriibio el usuario, quitar los espacios en blanco al inicio y al final
   final email = _emailCtrl.text.trim();
   final pass = _passCtrl.text;

   //4.6 Evaluar los erroes
   final eError = isValidEmail(email) ? null : 'Invalid Email';
   final pError = isValidPassword(pass) ? null : 'Invalid Password';

   //4.7 Avisar que hubo cambios
   setState(() {
      emailError = eError;
        passError = pError;
    });

    //4.8 Cerrar el teclado y bajar las manos del osito
    FocusScope.of(context).unfocus(); //Quita el foco
    _typingDebounce?.cancel(); //Cancelar el timer
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0; //Mirada neutra

    //4.9 Activar triggers
    if (eError == null && pError == null) {
      _trigSuccess?.fire();
    } else {
      _trigFail?.fire();
    }
  }
  //2.2 Listeners (Oyentes/chismosos) para saber cuando el usuario esta escribiendo en el campo de texto
  @override
  void initState() {
  super.initState();
    super.initState();
    _emailFocus.addListener((){
      if (_emailFocus.hasFocus) {
        //Verificar que no sea nulo
        if (_isHandsUp != null) {
          //Manos abajo en el email
          _isHandsUp!.change(false);
          //3.4 Mirada neutra
          _numLook?.value = 50.0;
        }
      }
    });
    _passWordFocus.addListener((){
      //Manos arriba en el password
      _isHandsUp!.change(_passWordFocus.hasFocus);
    });
  }
  @override
  Widget build(BuildContext context) {
    //Para obtener el tamaño de la pantalla
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(
                  width: size.width,
                  height: 200,
                  child: RiveAnimation.asset(
                    'assets/login-bear.riv',
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
                      //3.5 Vincular numLook
                      _numLook = _controller?.findSMI('numLook');
                    },
                  )
                ),
                //Sizedbox para separar espacios
                SizedBox(height: 10),
                //Campo de texto para el correo
                TextField(
                  //4.10 Anlazar controller
                  controller: _emailCtrl,
                  //2.3 Asigna el foco al campo de texto
                  focusNode: _emailFocus,
                  onChanged: (value){
                    if (_isHandsUp != null) {
                      //No tapes los ojos al ver email
                      //_isHandsUp!.change(false);
                    }
                    //Si isChecking no es nulo, cambiar el valor de la variable
                    if (_isChecking != null) {
                      //Activar modo chismoso
                      _isChecking!.change(true);
        
                      //3.6 Implementar numLook
                      //Ajustes de límites del 0 al 100
                      //80 es la medida de calibración para mirar al email
                      final look = (value.length / 80.0 * 100.0).clamp(0.0, 100.0);
                      //clamp es el rango (abrazadera) para que no se pase de 0 a 100
                      _numLook?.value = look;
        
                      //3.7 Debouce: si vuelve a teclear, reinicia el contador
                      //Cancelar cualquier timer existente
                      _typingDebounce?.cancel();
                      //crear un nuevo timer
                      _typingDebounce = Timer(const Duration(seconds: 3), (){
                        //Si se cierra la pantalla, quita el contador
                        if (!mounted) return;
                        //Mirada neutra
                        _isChecking?.change(false);
                      });
                    }
                  },
                  //para mostrar el tipo de teclado
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    //4.11 Mostrar el error en la UI
                    errorText: emailError,
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
                  //4.10 Anlazar controller
                  controller: _passCtrl,
                  //2.3 Asigna el foco al campo de texto
                  focusNode: _passWordFocus,
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
                    //4.11 Mostrar el error en la UI
                    errorText: passError,
                    hintText: 'Password',
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
                const SizedBox(height: 10),
                //4.12 Texto de olvide la contraseña
                SizedBox(
                  width: size.width,
                  child: const Text(
                    'Forgot Password?',
                    //alinear a la derecha
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                    )
                  ),
                ),
                const SizedBox(height: 10),
                //4.13 boton de login
                MaterialButton(
                  minWidth: size.width,
                  height: 50,
                  color: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onPressed: _onLogin,
                  child: Text(
                    'Login',
                    style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: (){},
                        child: Text('Sign Up',
                        style: TextStyle(
                          color: Colors.black,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                        ),
                        )
                      )
                    ],
                  )
                )
              ]
            ),
            ),
          ),
      ),
      );
  }
  @override
  void dispose() {
    //4.15 Liberar los controladores
    _emailCtrl.dispose();
    _passCtrl.dispose();
    //2.4 Liberar memoria al salir de la pantalla para liberar el foco
    _emailFocus.dispose();
    _passWordFocus.dispose();
    _typingDebounce?.cancel(); //3.8  Cancelar el timer al salir de la pantalla
    super.dispose();
  }
}