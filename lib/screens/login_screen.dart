
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async';

//5.1 Firebase Auth y pantalla de productos
import 'package:firebase_auth/firebase_auth.dart';
import 'products_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //Control para mostrar u ocultar la contraseña
  bool _obscure = true;

  //5.1 Remember me
  bool _rememberMe = false;

  //5.2 Evitar múltiples intentos de login
  bool _isBusy = false;

  //5.2.1 Indicador de carga

  //5.4 Nombres de estados de Rive
  static const String _successState = 'success';
  static const String _failState = 'fail';
  static const String _idleState = 'idle';

  //5.4.1 Indica si ya vimos pasar el estado de éxito
  bool _sawResultState = false;

  //1.1 Controlador de la animación
  StateMachineController? _controller;

  //SMT: State Machine Input
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;

  //3.2 Variable del recorrido de la mirada
  SMINumber? _numLook;

  //3.3 Timer para detener la mirada
  Timer? _typingDebounce;

  //2.1 FocusNodes
  final _emailFocus = FocusNode();
  final _passWordFocus = FocusNode();

  //4.1 Controllers
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  //4.2 Errores para mostrarlos en la UI
  String? emailError;
  String? passError;

   //5.2 Variable para mostrar el CircularProgressIndicator mientras carga
  bool _isLoading = false;
  
  //4.3 Validar email y contraseña
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

  //5.4.1 Escuchar los cambios de estado de Rive
  void _onRiveStateChange(String machineName, String stateName) {
    debugPrint(
      'Rive -> maquina: $machineName | estado: $stateName',
    );

    if (!mounted || !_isBusy) return;

    final name = stateName.toLowerCase();

    if (name == _successState || name == _failState) {
      _sawResultState = true;
      return;
    }

    if (_sawResultState && name == _idleState) {
      debugPrint('Rive regreso al estado idle');
    }
  }

  //4.4 Dar acción al botón de login
  //5.3 Convertir el método en asíncrono
  Future<void> _onLogin() async {
    //Evitar múltiples intentos
    if (_isBusy) return;

    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    final eError = isValidEmail(email) ? null : 'Invalid Email';
    final pError = isValidPassword(pass) ? null : 'Invalid Password';

    setState(() {
      emailError = eError;
      passError = pError;
    });

    //4.9 Si algún campo tiene formato inválido
    if (eError != null || pError != null) {
      _trigFail?.fire();
      return;
    }

    //Cerrar teclado y preparar animación
    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();

    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    //5.4 Activar indicador de carga
    setState(() {
      _isBusy = true;
      _isLoading = true;
      _sawResultState = false;
    });

    try {
      //5.5 Autenticar usuario con Firebase
      //Espera temporal para visualizar el indicador
      await Future.delayed(const Duration(seconds: 2));

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      if (!mounted) return;

      //Autenticación exitosa
      _trigSuccess?.fire();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ProductsScreen(),
        ),
      );

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      //Autenticación fallida
      _trigFail?.fire();

      setState(() {
        passError = 'Invalid email or password';
      });

      debugPrint('Firebase Auth Error: ${e.code}');

    } catch (e) {
      if (!mounted) return;

      _trigFail?.fire();

      setState(() {
        passError = 'An unexpected error occurred';
      });

      debugPrint('Login Error: $e');

    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isBusy = false;
        });
      }
    }
  }

  //5.8 Cambiar estado de Remember me
  void _toggleRemember(bool? value) {
    if (_isBusy) return;

    setState(() {
      _rememberMe = value ?? !_rememberMe;
    });
  }

  //2.2 Listeners para saber cuándo el usuario está escribiendo
  @override
  void initState() {
    super.initState();

    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        if (_isHandsUp != null) {
          _isHandsUp!.change(false);
          _numLook?.value = 50.0;
        }
      }
    });

    _passWordFocus.addListener(() {
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

            //Bloquear toques mientras se procesa el login
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

                      //1.2 Vincular animación
                      onInit: (artboard) {
                        _controller =
                            StateMachineController.fromArtboard(
                          artboard,
                          'Login Machine',
                          onStateChange: _onRiveStateChange,
                        );

                        //1.3 Verificar controlador
                        if (_controller == null) return;

                        artboard.addController(_controller!);

                        //Vincular variables
                        _isChecking =
                            _controller?.findSMI<SMIBool>('isChecking');

                        _isHandsUp =
                            _controller?.findSMI<SMIBool>('isHandsUp');

                        _trigSuccess =
                            _controller?.findSMI<SMITrigger>('trigSuccess');

                        _trigFail =
                            _controller?.findSMI<SMITrigger>('trigFail');

                        //3.5 Vincular numLook
                        _numLook =
                            _controller?.findSMI<SMINumber>('numLook');
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  //Campo de correo
                  TextField(
                    controller: _emailCtrl,
                    focusNode: _emailFocus,
                    onChanged: (value) {
                      if (_isChecking != null) {
                        _isChecking!.change(true);

                        //3.6 Movimiento de la mirada
                        final look =
                            (value.length / 80.0 * 100.0)
                                .clamp(0.0, 100.0);

                        _numLook?.value = look;

                        //3.7 Debounce
                        _typingDebounce?.cancel();

                        _typingDebounce = Timer(
                          const Duration(seconds: 3),
                          () {
                            if (!mounted) return;
                            _isChecking?.change(false);
                          },
                        );
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

                  //Campo de contraseña
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
                          _obscure
                              ? Icons.visibility
                              : Icons.visibility_off,
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

                  //5.10 Remember me y Forgot Password
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
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  //5.6 Botón con CircularProgressIndicator
                  MaterialButton(
                    minWidth: size.width,
                    height: 50,
                    color: Colors.pinkAccent,
                    disabledColor: Colors.pinkAccent.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onPressed: _isBusy ? null : _onLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 25,
                            width: 25,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
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
    //Liberar controladores
    _emailCtrl.dispose();
    _passCtrl.dispose();

    //Liberar FocusNodes
    _emailFocus.dispose();
    _passWordFocus.dispose();

    //Cancelar timer
    _typingDebounce?.cancel();

    super.dispose();
  }
}
