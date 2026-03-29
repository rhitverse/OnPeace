import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:on_peace/colors.dart';

class CountrySelectScreen extends StatelessWidget {
  const CountrySelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff040406),
      appBar: AppBar(
        backgroundColor: const Color(0xff040406),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: whiteColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Select country",
          style: TextStyle(color: whiteColor),
        ),
      ),
      body: Builder(
        builder: (context) {
          Future.microtask(() {
            showCountryPicker(
              context: context,
              showPhoneCode: true,
              showSearch: true,
              onSelect: (country) {
                Navigator.pop(context, country);
              },
              countryListTheme: CountryListThemeData(
                backgroundColor: const Color(0xff040406),
                textStyle: const TextStyle(color: whiteColor),
                searchTextStyle: const TextStyle(color: whiteColor),
                inputDecoration: InputDecoration(
                  hintText: 'Search country',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xff1e2023),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            );
          });
          return const SizedBox();
        },
      ),
    );
  }
}
