import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nodo/core/theme/app_theme.dart';
import 'package:nodo/core/utils/debug_log.dart';
import 'package:nodo/features/register/logic/register_controller.dart';
import 'package:nodo/shared/providers/general_category_provider.dart';
import 'package:nodo/shared/providers/location_provider.dart';
import 'package:nodo/models/categorie.dart';
import 'package:nodo/models/location.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:nodo/shared/widgets/elevated_button_widget.dart';
import 'package:nodo/shared/widgets/multi_select_dropdown.dart';
import 'package:nodo/shared/widgets/password_form_field.dart';
import 'package:nodo/shared/widgets/searchable_dropdown_field.dart';

class FormWidget extends StatefulWidget {
  final VoidCallback onContinue; // 🔹 callback para avanzar al siguiente paso
  final String? initialUserType;

  const FormWidget({
    super.key,
    required this.onContinue,
    this.initialUserType,
  });

  @override
  State<FormWidget> createState() => _FormWidgetState();
}

class _FormWidgetState extends State<FormWidget> {
  String? selectedUserType;
  DateTime? selectedDate;
  final _formKey = GlobalKey<FormState>();
  bool _obscurePasswords = true;

  @override
  void initState() {
    super.initState();
    selectedUserType = widget.initialUserType;
  }

  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastName1Controller = TextEditingController();
  final TextEditingController lastName2Controller = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController emailController = TextEditingController();

  List<String> selectedCategories = [];

  @override
  Widget build(BuildContext context) {
    final categorieProvider = context.watch<GeneralCategoryProvider>();
    final locationProvider = context.watch<LocationProvider>();
    if (categorieProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final registerController = Provider.of<RegisterController>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final fieldSpacing = 10.h;
    final categorySpacing = 15.h;
    final textSpacing = 5.h;
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 5.h, vertical: 20.h),
          constraints: BoxConstraints(maxWidth: screenWidth * 0.9),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Texto introductorio
                Text(
                  "En NODO creemos en el poder de unir necesidades con talentos. Regístrate y sé parte de una red que impulsa el trabajo real.",
                  style: AppTypography.body.copyWith(color: AppColors.blue),
                  textAlign: TextAlign.justify,
                ),

                SizedBox(height: categorySpacing),

                Text(
                  "¿Cómo quieres comenzar en Nodo?",
                  style: AppTypography.subtitle.copyWith(color: AppColors.orange),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: textSpacing),

                Text(
                  "Elige si deseas buscar servicios como cliente o empezar a trabajar ofreciendo tu talento.",
                  style: AppTypography.body.copyWith(color: AppColors.blue),
                  textAlign: TextAlign.justify,
                ),
                SizedBox(height: textSpacing),

                Text(
                  "Podrás cambiar de rol más adelante si lo deseas.",
                  style: AppTypography.body.copyWith(color: AppColors.blue),
                ),
                SizedBox(height: fieldSpacing),

                // Selector de tipo de usuario
                DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: "Tipo de usuario"),
                  initialValue: selectedUserType,
                  items: const [
                    DropdownMenuItem(value: "cliente", child: Text("Cliente")),
                    DropdownMenuItem(
                        value: "trabajador", child: Text("Trabajador")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedUserType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    return null;
                  },
                ),

                SizedBox(height: categorySpacing),

                // Información básica
                Text(
                  "Información básica",
                  style: AppTypography.subtitle.copyWith(color: AppColors.blue),
                ),
                SizedBox(height: fieldSpacing),

                TextFormField(
                  decoration: const InputDecoration(labelText: "Nombre(s)"),
                  controller: nameController,
                  //widthPercentage: 0.85,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s]+$")
                        .hasMatch(value)) {
                      return 'Solo se permiten letras';
                    }
                    return null;
                  },
                ),
                SizedBox(height: fieldSpacing),
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: "Primer apellido"),
                  controller: lastName1Controller,
                  //widthPercentage: 0.85,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s]+$")
                        .hasMatch(value)) {
                      return 'Solo se permiten letras';
                    }
                    return null;
                  },
                ),
                SizedBox(height: fieldSpacing),
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: "Segundo apellido"),
                  controller: lastName2Controller,
                  //widthPercentage: 0.85,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s]+$")
                        .hasMatch(value)) {
                      return 'Solo se permiten letras';
                    }
                    return null;
                  },
                ),
                SizedBox(height: fieldSpacing),
                TextFormField(
                  //label: 'Cédula',
                  controller: idController,
                  //widthPercentage: 0.85,
                  decoration: const InputDecoration(labelText: "Cédula"),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    if (!RegExp(r"^\d{1,10}$").hasMatch(value)) {
                      return 'Debe contener solo números (máx. 10 dígitos)';
                    }
                    return null;
                  },
                ),

                SizedBox(height: categorySpacing),

                // Datos de contacto
                Text(
                  "Datos de contacto y seguridad",
                  style: AppTypography.subtitle.copyWith(color: AppColors.blue),
                ),
                SizedBox(height: fieldSpacing),
                TextFormField(
                  controller: emailController,
                  decoration:
                      const InputDecoration(labelText: "Correo electrónico"),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Ingresa un correo electrónico válido';
                    }
                    return null;
                  },
                ),

                SizedBox(height: fieldSpacing),

                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: "Celular",
                    prefixText: "+57 ",
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    // Firebase envía el código por SMS: tiene que ser un celular.
                    if (!RegExp(r"^3\d{9}$").hasMatch(value.trim())) {
                      return 'Ingresa un celular de 10 dígitos que empiece por 3';
                    }
                    return null;
                  },
                ),
                SizedBox(height: fieldSpacing),

                // Campo de fecha integrado en el Form para que su validator funcione
                FormField<DateTime>(
                  initialValue: selectedDate,
                  validator: (value) {
                    if (value == null) return 'Por favor selecciona una fecha';
                    return null;
                  },
                  builder: (field) {
                    final isEmpty = field.value == null;
                    final effectiveLabel = 'Fecha de nacimiento';

                    return GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: field.context,
                          initialDate: field.value ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          field.didChange(picked); // actualiza el valor
                          setState(() {
                            selectedDate = picked;
                            dateController.text =
                                DateFormat('dd/MM/yyyy').format(picked);
                          });
                        }
                      },
                      child: InputDecorator(
                        isEmpty: isEmpty,
                        decoration: InputDecoration(
                          labelText: effectiveLabel,
                          errorText: field.errorText,
                        ),
                        child: Text(
                          isEmpty
                              ? ''
                              : DateFormat('dd/MM/yyyy').format(field.value!),
                          style: TextStyle(
                            color: isEmpty ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: categorySpacing),

                // Datos adicionales (solo si es trabajador)
                if (selectedUserType == "trabajador") ...[
                  Text(
                    "Datos adicionales",
                    style:
                        AppTypography.subtitle.copyWith(color: AppColors.blue),
                  ),
                  SizedBox(height: fieldSpacing),
                  SearchableDropdownField<Location>(
                    label: "Ubicación o zona de servicio",
                    icon: Icons.location_on_outlined,
                    searchHint: "Buscar ubicación...",
                    emptyMessage: "No se encontraron ubicaciones",
                    options: locationProvider.locations,
                    labelBuilder: (location) => location.name,
                    value: locationProvider.locations.cast<Location?>().firstWhere(
                          (l) => l!.name == locationController.text,
                          orElse: () => null,
                        ),
                    onChanged: (location) =>
                        setState(() => locationController.text = location.name),
                  ),
                  SizedBox(height: fieldSpacing),
                  Text(
                    "Rubros",
                    style:
                        AppTypography.subtitle.copyWith(color: AppColors.blue),
                  ),
                  SizedBox(height: textSpacing),
                  Text(
                    "Selecciona las áreas en las que tienes experiencia o deseas ofrecer tus servicios.",
                    style: AppTypography.label.copyWith(color: AppColors.blue),
                  ),
                  SizedBox(height: fieldSpacing),
                  MultiSelectDropdown<Categorie>(
                    label: 'Rubros',
                    hint: 'Selecciona tus rubros',
                    options: categorieProvider.categories,
                    selectedValues: categorieProvider.categories
                        .where((c) => selectedCategories.contains(c.id))
                        .toList(),
                    labelBuilder: (categoria) => categoria.name,
                    onChanged: (selected) {
                      setState(() {
                        selectedCategories = selected.map((c) => c.id).toList();
                      });
                    },
                  ),
                  SizedBox(height: fieldSpacing),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                        labelText: "Descripción breve de los servicios"),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Este campo es obligatorio';
                      }
                      return null;
                    },
                    maxLines: 3,
                  ),
                  SizedBox(height: categorySpacing),
                ],

                // Crear contraseña
                Text(
                  "Crea una contraseña",
                  style: AppTypography.subtitle.copyWith(color: AppColors.blue),
                ),
                SizedBox(height: textSpacing),

                Text(
                  "Debe tener mínimo 8 caracteres, combinar letras mayúsculas, minúsculas, números y símbolos.",
                  style: AppTypography.label.copyWith(color: AppColors.blue),
                ),
                SizedBox(height: fieldSpacing),

                PasswordFormField(
                  controller: passwordController,
                  labelText: "Contraseña",
                  obscureText: _obscurePasswords,
                  onToggleVisibility: () {
                    setState(() {
                      _obscurePasswords = !_obscurePasswords;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    return null;
                  },
                ),
                SizedBox(height: fieldSpacing),

                PasswordFormField(
                  controller: confirmPasswordController,
                  labelText: "Confirma tu contraseña",
                  obscureText: _obscurePasswords,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    if (value != passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                SizedBox(height: categorySpacing * 2),
                CustomElevatedButton(
                  text: "Completar registro",
                  onPressed: registerController.isLoading
                      ? null
                      : () async {
                          logPaso('Formulario', 'Botón "Completar registro" presionado');

                          // Validar el formulario y registrar qué campos fallan
                          final invalidos =
                              _formKey.currentState!.validateGranularly();
                          if (invalidos.isNotEmpty) {
                            for (final campo in invalidos) {
                              logPaso('Formulario',
                                  '✗ Campo inválido: ${campo.errorText}');
                            }
                            logPaso('Formulario',
                                'Se detiene: ${invalidos.length} campo(s) con error');
                            // El error puede quedar fuera de la pantalla:
                            // llevar al usuario hasta el primero.
                            Scrollable.ensureVisible(
                              invalidos.first.context,
                              duration: const Duration(milliseconds: 300),
                              alignment: 0.2,
                            );
                            return;
                          }
                          logPaso('Formulario',
                              '✓ Campos válidos · tipo de usuario: $selectedUserType');

                          // Validar ubicación si es trabajador (no es un TextFormField, no la valida el Form)
                          if (selectedUserType == "trabajador" &&
                              locationController.text.trim().isEmpty) {
                            logPaso('Formulario', '✗ Trabajador sin ubicación seleccionada');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Por favor selecciona tu ubicación'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          // Validar que seleccione al menos una categoría si es trabajador
                          if (selectedUserType == "trabajador" &&
                              selectedCategories.isEmpty) {
                            logPaso('Formulario', '✗ Trabajador sin rubros seleccionados');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Por favor selecciona al menos un rubro'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return; // 🚫 Detiene la ejecución
                          }
                          await registerController.prepareRegistration(
                            context: context,
                            formKey: _formKey,
                            nameController: nameController,
                            lastName1Controller: lastName1Controller,
                            lastName2Controller: lastName2Controller,
                            idController: idController,
                            phoneController: phoneController,
                            dateController: dateController,
                            locationController: locationController,
                            selectedCategories: selectedCategories,
                            descriptionController: descriptionController,
                            passwordController: passwordController,
                            confirmPasswordController:
                                confirmPasswordController,
                            selectedUserType: selectedUserType,
                            emailController: emailController,
                            onContinue: widget.onContinue,
                          );
                        },
                  loading: registerController.isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
