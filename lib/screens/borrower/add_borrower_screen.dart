import 'package:flutter/material.dart';
import '../../models/borrower_model.dart';
import '../../services/database_helper.dart';
import 'package:geolocator/geolocator.dart';

class AddBorrowerScreen extends StatefulWidget{
  const AddBorrowerScreen({super.key});

  @override
  State<AddBorrowerScreen> createState() => _AddBorrowerScreenState();
}

class _AddBorrowerScreenState extends State<AddBorrowerScreen>{
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  bool isLoading  = false;

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {   
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }


  Future<void> _saveBorrower() async {
    if (!_formKey.currentState!.validate() && !await _handleLocationPermission()) return;

    Position position = await Geolocator.getCurrentPosition();
    setState(()=> isLoading = true);

    final borrower = Borrower(
      name:nameController.text.trim(),
      status:1,
      phone: phoneController.text.trim(),
      address: addressController.text.trim(),
      latitude: position.latitude,
      longitude: position.longitude,
      createdAt: DateTime.now().toString(),
      isSynced: 0,
    );

    await DatabaseHelper().insertBorrower(borrower);
    setState(()=> isLoading = false);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Borrower")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 👤 Name
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (value) =>
                    value!.isEmpty ? "Enter name" : null,
              ),

              const SizedBox(height: 10),

              // 📞 Phone
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Phone"),
                validator: (value) =>
                    value!.isEmpty ? "Enter phone" : null,
              ),

              const SizedBox(height: 10),

              // 📍 Address
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: "Address"),
                validator: (value) =>
                    value!.isEmpty ? "Enter address" : null,
              ),

              const SizedBox(height: 20),

              // 💾 Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveBorrower,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Save Borrower"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}