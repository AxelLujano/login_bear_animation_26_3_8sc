import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async'; //3.1 Importar el timer

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //Control para mostrar u ocultar la contraseña
  bool _obscure = true;

  //5.1 remember me efecto visual
  bool _rememberMe = false;

  //5.2 el anti spam
  bool _isBusy = false;

  //5.3 Timer de RESPALDO
  Timer? _lockTimer;
  static const Duration _fallbackLock = Duration(seconds: 6);

  //5.4 Nombres de estados
  static const String _successState = 'success';
  static const String _failState = 'fail';
  static const String _idleState = 'idle';

  //5.4.1 indica si ya vimos pasar el estado de exito
  bool _sawResultState = false;

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
  final _emailFocus = FocusNode();
  final _passWordFocus = FocusNode();

  //4.1 Controllers que manipulan lo que el usuario escribe
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  //4.2 Errores para mostarlo en la UI(pantalla)
  String? emailError;
  String? passError;

  //4.3 Validar el email y la contraseña
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }

  //5.13 Rive nos avisa cada vez que la maquina de estados cambia de estado
  void _onRiveStateChange(String machineName, String stateName) {
    //Imprime los nombres reales para ajustar las constantes de arriba
    debugPrint('Rive -> maquina: $machineName | estado: $stateName');

    if (!mounted || !_isBusy) return;

    final name = stateName.toLowerCase();

    //la animacion llego al estado de exito o fallo
    if (name == _successState || name == _failState) {
      _sawResultState = true;
      return;
    }

    //regreso al reposo osea el desbloquear
    if (_sawResultState && name == _idleState) {
      _lockTimer?.cancel();
      setState(() => _isBusy = false);
    }
  }

  //4.4 Dar accion al boton de login
  void _onLogin() {
    //5.5 Si ya hay una animacion en curso, ignorar el click
    if (_isBusy) return;

    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    final eError = isValidEmail(email) ? null : 'Invalid Email';
    final pError = isValidPassword(pass) ? null : 'Invalid Password';

    //4.7 Avisar que hubo cambios + 5.6 bloquear la UI
    setState(() {
      emailError = eError;
      passError = pError;
      _isBusy = true;
      _sawResultState = false;
    });

    //4.8 Cerrar el teclado y bajar las manos del osito
    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0; //Mirada neutra

    //4.9 Activar triggers
    if (eError == null && pError == null) {
      _trigSuccess?.fire();
    } else {
      _trigFail?.fire();
    }

    //5.7 Respaldo: si Rive no avisa, desbloquear despues de _fallbackLock
    _lockTimer?.cancel();
    _lockTimer = Timer(_fallbackLock, () {
      if (!mounted) return;
      setState(() => _isBusy = false);
    });
  }

  //5.8 Cambiar el estado de Remember me
  void _toggleRemember(bool? value) {
    if (_isBusy) return;
    setState(() => _rememberMe = value ?? !_rememberMe);
  }

  //2.2 Listeners para saber cuando el usuario esta escribiendo
  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        if (_isHandsUp != null) {
          _isHandsUp!.change(false);
          //3.4 Mirada neutra
          _numLook?.value = 50.0;
        }
      }
    });
    _passWordFocus.addListener(() {
      //Manos arriba en el password (con ? por si la animacion aun no carga)
      _isHandsUp?.change(_passWordFocus.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            //5.9 AbsorbPointer bloquea todos los toques mientras _isBusy sea true
            child: AbsorbPointer(
              absorbing: _isBusy,
              child: Column(
                children: [
                  SizedBox(
                    width: size.width,
                    height: 200,
                    child: RiveAnimation.asset(
                      'assets/login-bear.riv',
                      stateMachines: const ['Login Machine'],
                      //1.2 Vincular Animacion
                      onInit: (artboard) {
                        _controller = StateMachineController.fromArtboard(
                          artboard,
                          'Login Machine',
                          //5.14 Escuchar los cambios de estado de la animacion
                          onStateChange: _onRiveStateChange,
                        );

                        //1.3 Verificar que el controlador no sea nulo
                        if (_controller == null) return;
                        artboard.addController(_controller!);
                        //Vinculamos variables
                        _isChecking =
                            _controller?.findSMI<SMIBool>('isChecking');
                        _isHandsUp = _controller?.findSMI<SMIBool>('isHandsUp');
                        _trigSuccess =
                            _controller?.findSMI<SMITrigger>('trigSuccess');
                        _trigFail =
                            _controller?.findSMI<SMITrigger>('trigFail');
                        //3.5 Vincular numLook
                        _numLook = _controller?.findSMI<SMINumber>('numLook');
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  //Campo de texto para el correo
                  TextField(
                    controller: _emailCtrl,
                    focusNode: _emailFocus,
                    onChanged: (value) {
                      if (_isChecking != null) {
                        //Activar modo chismoso
                        _isChecking!.change(true);

                        //3.6 Implementar numLook (0 a 100, 80 = calibracion)
                        final look =
                            (value.length / 80.0 * 100.0).clamp(0.0, 100.0);
                        _numLook?.value = look;

                        //3.7 Debounce: si vuelve a teclear, reinicia el contador
                        _typingDebounce?.cancel();
                        _typingDebounce = Timer(const Duration(seconds: 3), () {
                          if (!mounted) return;
                          _isChecking?.change(false);
                        });
                      }
                    },
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      errorText: emailError,
                      hintText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  //Campo de texto para la contraseña
                  TextField(
                    controller: _passCtrl,
                    focusNode: _passWordFocus,
                    onChanged: (value) {
                      _isChecking?.change(false);
                      _isHandsUp?.change(true);
                    },
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      errorText: passError,
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscure = !_obscure;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  //5.10 Fila: Remember me (izquierda) + Forgot Password (derecha)
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _toggleRemember(!_rememberMe),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              activeColor: Colors.pinkAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: _toggleRemember,
                            ),
                            const Text('Remember me'),
                            const SizedBox(width: 4),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Forgot Password?',
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  //4.13 boton de login
                  MaterialButton(
                    minWidth: size.width,
                    height: 50,
                    color: Colors.pinkAccent,
                    //5.11 Look de deshabilitado mientras corre la animacion
                    disabledColor: Colors.pinkAccent.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    //null = boton deshabilitado
                    onPressed: _isBusy ? null : _onLogin,
                    child: const Text(
                      'Login',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: size.width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?"),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.black,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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

  @override
  void dispose() {
    //4.15 Liberar los controladores
    _emailCtrl.dispose();
    _passCtrl.dispose();
    //2.4 Liberar el foco
    _emailFocus.dispose();
    _passWordFocus.dispose();
    _typingDebounce?.cancel(); //3.8 Cancelar el timer al salir
    _lockTimer?.cancel(); //5.12 Cancelar el timer del bloqueo
    super.dispose();
  }
}