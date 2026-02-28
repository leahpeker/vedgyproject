import 'package:flutter/material.dart';

import '../widgets/listing_form.dart';

class CreateListingScreen extends StatelessWidget {
  const CreateListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ListingForm(),
    );
  }
}
