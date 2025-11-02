// ignore_for_file: use_build_context_synchronously

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Registration Page',
      home: RegistrationWorkerPage(),
    );
  }
}

class RegistrationWorkerPage extends StatefulWidget {
  const RegistrationWorkerPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationWorkerPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController companyPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Add a GlobalKey for the form

  bool isCompanyListVisible = false;
  final TextEditingController companySearchController = TextEditingController();
  List<String> filteredCompanies = [];

  List<String> companyNames = [];
  String selectedCompany = '';
  Map<dynamic, dynamic> companies = {};

  final FirebaseAuth _auth =
      FirebaseAuth.instance; // Define _auth at class level
  final DatabaseReference _dbRef =
      // ignore: deprecated_member_use
      FirebaseDatabase.instance.reference(); // Define _dbRef at class level

  @override
  void initState() {
    super.initState();
    fetchCompanyNames();
    companySearchController.addListener(() {
      onSearchTextChanged(companySearchController.text);
    });
  }
/// Prikaže popup dialog z naslovom in besedilom dokumenta.
void _showPolicyDialog(BuildContext context, String title, String content) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(content)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Zapri'),
        ),
      ],
    ),
  );
}

void _showUsageDialog(BuildContext context, String title, String content) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(content)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Zapri'),
        ),
      ],
    ),
  );
}

  Future<void> fetchCompanyNames() async {
    final DatabaseEvent companyDataSnapshot =
        await _dbRef.child("companies").once();
    if (companyDataSnapshot.snapshot.value != null) {
      companies = companyDataSnapshot.snapshot.value as Map<dynamic, dynamic>;
      final names = companies.keys
          .map((key) => companies[key]['name'].toString())
          .toList();
      setState(() {
        companyNames = names;
        selectedCompany = companyNames.isNotEmpty ? companyNames.first : '';
      });
    }
  }

  void onSearchTextChanged(String query) {
    setState(() {
      filteredCompanies = companyNames.where((company) {
        return company.toLowerCase().contains(query.toLowerCase());
      }).toList();
      isCompanyListVisible = true; // Show the list when there's a search query
    });
  }

  Widget _buildRoundedInput({
    required String labelText,
    required TextEditingController controller,
    required double height,
    bool obscureText = false,
  }) {
    return Card(
      elevation: 5.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: height * 0.02,
            vertical: 0.0), // Adjusted vertical padding
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: (value) {
            // Check if the registration button has been pressed before showing validation error
            if (value == null || value.isEmpty) {
              return 'To polje je obvezno';
            }

            return null;
          },
          style: TextStyle(fontSize: height * 0.021), // Adjusted font size

          decoration: InputDecoration(
            labelText: labelText,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    EdgeInsets padding = MediaQuery.of(context).padding;
    double topPadding = padding.top;
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    var _acceptedPrivacyPolicy=false;
    const String privacyPolicy = '''
 Pravilnik o varstvu osebnih podatkov aplikacije Štempl 

 1. Upravljavec osebnih podatkov   
Upravljavec osebnih podatkov je  
[Naziv podjetja], naslov: [Ulica in hišna številka], [Pošta in kraj], Slovenija, matična številka: [Matična številka], davčna številka: [Davčna številka] (v nadaljevanju: „Upravljavec“).

 2. Namen in pravna podlaga obdelave   
1.  Evidentiranje delovnega časa   
   - Podatki: časovni žigi (začetek/konec seje, odmori), uporabniška identifikacija (userId), vrsta dela.  
   - Pravna podlaga: izpolnitev pravne obveznosti delodajalca glede vodenja evidence po ZDR-1 in ZEPDSV-A (člen 6(1)(c) GDPR).  
2.  Avtentikacija in uporaba aplikacije   
   - Podatki: e-poštni naslov, geslo (shranjeno kot hash), uporabniška vloga, soglasje k pravilniku in pogojem uporabe.  
   - Pravna podlaga: izpolnitev pogodbenih obveznosti in privolitev uporabnika (člen 6(1)(b) in 6(1)(a) GDPR).  
3.  Statistična analiza in izboljšave   
   - Podatki: anonimni agregirani podatki o številu sej, času vnosa, morebitna geolokacija (če je bila izrecno dovoljena).  
   - Pravna podlaga: zakoniti interes Upravljavca za izboljšanje aplikacije (člen 6(1)(f) GDPR), ob upoštevanju pravic uporabnika.

 3. Vrste obdelovanih podatkov   
- Identifikacijski podatki: userId, email.  
- Časovni podatki: timestamp začetka in konca seje ter odmora.  
- Tehnični podatki: IP-naslov, podatki o napravi (tip, operacijski sistem).  
- Soglasja in nastavitve: potrditvena polja za pravilnik in pogoje uporabe.

 4. Prejemniki podatkov   
-  Interni prejemniki : skrbniki sistema in kadrovska služba Upravljavca za potrebe obračuna ur in zakonskih poročil.  
-  Zunanji prejemniki :  
  - Google LLC (Firebase Authentication, Firestore) kot upravljavec obdelave.  
  - Pooblaščeni ponudniki IT vzdrževanja aplikacije (po potrebi).

 5. Obdobje hrambe   
-  Uporabniški profili  (users): do prenehanja delovnega razmerja in dodatnih 2 leti shrambe zaradi pravnih zahtev.  
-  Evidence sej  (sessions): trajno kot listina trajne vrednosti, vsaj do prenehanja delovnega razmerja.  
-  Agregirani statistični podatki : do 5 let, anonimno.

 6. Pravice posameznika   
Vsak uporabnik ima pravico do:  
1.  Dostopa  do svojih osebnih podatkov (člen 15 GDPR).  
2.  Popravka  netočnih podatkov (člen 16 GDPR).  
3.  Izbrisa  osebnih podatkov („pravica do pozabe“) ob izpolnitvi pogojev (člen 17 GDPR).  
4.  Omejitve obdelave  (člen 18 GDPR).  
5.  Prenosljivosti podatkov  v strojno berljivi obliki (člen 20 GDPR).  
6.  Ugovora  proti obdelavi na podlagi zakonitih interesov (člen 21 GDPR).  

Pravice lahko uveljavljate z e-pošto na naslov: privacy@[vasadomena].si ali pisno na naslov Upravljavca.

 7. Tehnični in organizacijski ukrepi   
- Vsi prenosi potekajo po protokolu TLS.  
- Baza Firestore je šifrirana “at rest”.  
- Dostop do baze je zaščiten s Firebase Security Rules, ki omogočajo branje/pisanje le overjenim uporabnikom za njihove podatke.  
- Redni varnostni pregledi in revizija logov.

 8. Posredovanje podatkov v tretje države   
Podatki so shranjeni na strežnikih Google znotraj EU/EEA. Podatki se ne posredujejo v tretje države, razen v primeru zakonske obveznosti.

 9. Pristojni nadzorni organ   
Uporabniku pripada pravica vložiti pritožbo pri Informacijskem pooblaščencu Republike Slovenije (gp.ip@ip-rs.si), če meni, da je obdelava njegovih podatkov ni v skladu z GDPR.

Z označitvijo potrditvenih polj na zaslonu registracije potrjujete, da ste bili seznanjeni s to politiko in se z njo strinjate. 
''';
const String termsAndConditions = '''
Pogoji uporabe aplikacije Štempl

1. Uvod
Dobrodošli v aplikaciji Štempl. Z uporabo aplikacije se strinjate s temi Pogoji uporabe (Pogoji). Če se ne strinjate z vsebino, aplikacije ne uporabljajte.

2. Definicije
- Aplikacija: mobilni in spletni odjemalec Štempl, razvit v Flutterju.
- Uporabnik: fizična oseba, ki uporablja aplikacijo za evidentiranje delovnega časa.
- Upravljavec: [Naziv podjetja], ki zagotavlja aplikacijo in storitve.

3. Dostop in registracija
- Za uporabo aplikacije se je potrebno registrirati z veljavnim e-poštnim naslovom.
- Uporabniško ime in geslo sta varovani in ju hranite zasebno.
- Upravljavec ima pravico začasno ali trajno onemogočiti račun ob kršitvi Pogojev.

4. Namen uporabe
Aplikacija Štempl je namenjena izključno evidentiranju delovnega časa in pripravi poročil. Vsaka druga uporaba, zloraba ali spreminjanje aplikacije je prepovedana.

5. Pravice in obveznosti uporabnika
- Uporabnik je dolžan zagotoviti točne in ažurne podatke ter jih redno posodabljati.
- Uporabnik ne sme uporabljati aplikacije za nezakonite ali nepooblaščene dejavnosti.
- Uporabnik ne sme poskušati vdorov, obhodov varnostnih omejitev ali spreminjanja kode.

6. Pravice in obveznosti upravljavca
- Upravljavec zagotavlja razpoložljivost aplikacije po najboljših močeh (cilj 99,5 % časa).
- Upravljavec lahko ob nadgradnjah, varnostnih popravkih ali izboljšavah aplikacijo začasno onemogoči.
- Upravljavec ne prevzema odgovornosti za morebitne prekinitve storitev izven njegovega nadzora (strežniške napake, internetne motnje).

7. Vsebina uporabniških podatkov
- Podatki o delovnih sejah so last delodajalca in se uporabljajo za obračun plač ter zakonito hrambo.
- Upravljavec ne odgovarja za napačno rabo ali izgubo teh podatkov zaradi nepooblaščenega dostopa uporabnikov.

8. Omejitev odgovornosti
- Aplikacija se zagotavlja kot je brez kakršnihkoli jamstev za primernost za določen namen.
- Upravljavec ne prevzema odgovornosti za neposredne ali posredne škode, ki bi nastale zaradi uporabe aplikacije.

9. Spremembe Pogojev
- Upravljavec lahko Pogoje kadar koli spremeni.
- O vsaki spremembi bomo obvestili uporabnike preko aplikacije ali na njihov e-poštni naslov.
- Nadaljnja uporaba aplikacije po spremembi Pogojev pomeni, da jih sprejemate.

10. Prenos pravic in obveznosti
- Upravljavec lahko pravice in obveznosti iz teh Pogojev prenese na tretjo osebo, o čemer vas bo vnaprej obvestil.

11. Prenehanje veljavnosti
- Uporabnik lahko kadar koli prekine uporabo aplikacije in zahteva izbris svojega računa.
- Upravljavec lahko brez predhodnega obvestila prekine vašo možnost dostopa ob kršitvi Pogojev.

12. Veljavno pravo in pristojnost
- Pogoje ureja pravo Republike Slovenije.
- Morebitne spore rešuje pristojno sodišče v [kraj].

Z označitvijo potrditvenih polj na zaslonu registracije potrjujete, da ste prebrali, razumeli in se strinjate s temi Pogoji uporabe.
''';

    var _acceptedtermsAndConditions = false;
    return Scaffold(
        body: Stack(
      children: [
        Positioned(
            child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.fromARGB(199, 119, 192, 252), Colors.white],
            ),
          ),
        )),
        Column(
          children: [
            Container(
              height: topPadding, // Set the desired height for your container
              color: Colors.black, // Your container color
            ),
            Stack(
              children: [
               
               
            Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                      size: screenHeight * 0.03,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  Text(
                    'REGISTRACIJA DELAVCA',
                    style: TextStyle(
                      fontSize: screenHeight * 0.03, // Adjusted size
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                        0.3), // Adjust the shadow color and opacity
                    blurRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Divider(
                color: Colors
                    .transparent, // Set the color of the Divider to transparent
                height: 1.0, // Set the thickness of the underline
              ),
            ),
            Expanded(
                child: Padding(
              padding: const EdgeInsets.all(0.0),
              child: CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.05), // Adjust the horizontal margin
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: screenHeight*0.02),
                                _buildRoundedInput(
                                    labelText: 'Ime',
                                    controller: nameController,
                                    height: screenHeight),
                                SizedBox(height: screenHeight*0.01),
                                _buildRoundedInput(
                                    labelText: 'Priimek',
                                    controller: surnameController,
                                    height: screenHeight),
                                SizedBox(height: screenHeight*0.01),
                                _buildRoundedInput(
                                    labelText: 'Email',
                                    controller: emailController,
                                    height: screenHeight),
                                SizedBox(height: screenHeight*0.01),
                                _buildRoundedInput(
                                    labelText: 'Geslo',
                                    controller: passwordController,
                                    obscureText: true,
                                    height: screenHeight),
                                SizedBox(height: screenHeight*0.01),
                                _buildRoundedInput(
                                    labelText: 'Poišči podjetje',
                                    controller: companySearchController,
                                    height: screenHeight),
                                Visibility(
                                  visible: isCompanyListVisible &&
                                      companySearchController.text.isNotEmpty,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors
                                          .white, // Set the background color
                                      borderRadius: BorderRadius.circular(
                                          15.0), // Adjust border radius as needed
                                      border: Border.all(
                                        color:
                                            Colors.grey, // Set the border color
                                        width: 1.0, // Set the border width
                                      ),
                                    ),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      itemCount: filteredCompanies.length,
                                      separatorBuilder:
                                          (BuildContext context, int index) {
                                        // Add a gray line separator
                                        return const Divider(
                                          color: Colors.grey,
                                          height: 1,
                                        );
                                      },
                                      itemBuilder: (context, index) {
                                        final sortedCompanies =
                                            filteredCompanies..sort();
                                        final company = sortedCompanies[index];
                                        return ListTile(
                                          title: Text(company),
                                          onTap: () {
                                            setState(() {
                                              selectedCompany = company;
                                              companySearchController.text =
                                                  company;
                                              isCompanyListVisible = false;
                                            });
                                            FocusScope.of(context)
                                                .unfocus(); // Hide the keyboard
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight*0.01),
                                _buildRoundedInput(
                                    labelText: 'Geslo podjetja',
                                    controller: companyPasswordController,
                                    height: screenHeight),
                                SizedBox(height: screenHeight*0.01),


CheckboxListTile(
  value: _acceptedPrivacyPolicy,
  onChanged: (v) => setState(() => _acceptedtermsAndConditions = v!),
  controlAffinity: ListTileControlAffinity.leading,
  title: RichText(
    text: TextSpan(
      style: Theme.of(context).textTheme.bodyText2,
      children: [
        TextSpan(text: 'Strinjam se s '),
        TextSpan(
          text: 'Pravilnikom o varstvu osebnih podatkov',
          style: TextStyle(decoration: TextDecoration.underline),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _showPolicyDialog(
              context,
              'Pravilnik o varstvu osebnih podatkov',
privacyPolicy )),
        TextSpan(text: '.'),
      ],
    ),
  ),
),



CheckboxListTile(
  value: _acceptedtermsAndConditions,
  onChanged: (v) => setState(() => _acceptedtermsAndConditions = v!),
  controlAffinity: ListTileControlAffinity.leading,
  title: RichText(
    text: TextSpan(
      style: Theme.of(context).textTheme.bodyText2,
      children: [
        TextSpan(text: 'Strinjam se s '),
        TextSpan(
          text: 'Pogoji uporabe aplikacije Štempl',
          style: TextStyle(decoration: TextDecoration.underline),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _showUsageDialog(
              context,
              'Pogoji uporabe aplikacije Štempl',
termsAndConditions )),
        TextSpan(text: '.'),
      ],
    ),
  ),
),




                                Center(
                                  child: Container(
                                    margin:  EdgeInsets.only(top: screenHeight*0.025),
                                    width: screenWidth,
                                    height: 50.0,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (_formKey.currentState != null &&
                                            _formKey.currentState!.validate()) {
                                          // Check if all required fields are not empty
                                          if (nameController.text.isNotEmpty &&
                                              surnameController
                                                  .text.isNotEmpty &&
                                              emailController.text.isNotEmpty &&
                                              passwordController
                                                  .text.isNotEmpty &&
                                              companySearchController
                                                  .text.isNotEmpty &&
                                              companyPasswordController
                                                  .text.isNotEmpty) {
                                            // All required fields are filled, proceed with registration
                                            registerUser();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const HomeScreen(),
                                              ),
                                            );
                                          } else {
                                            // Show a SnackBar if not all fields are filled
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Prosim izpolnite vsa polja za vstavljanje besedila!'),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        primary:
                                            Color.fromARGB(255, 33, 149, 243),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(35.0),
                                        ),
                                      ),
                                      child:  Text(
                                        'Registracija',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: screenHeight *
                                                0.023,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ],
    ));
  }

  Future<void> registerUser() async {
    final String name = nameController.text;
    final String surname = surnameController.text;
    final String email = emailController.text;
    final String password = passwordController.text;
    final String enteredCompanyPassword = companyPasswordController.text;

    // ... (rest of your code)
    String selectedCompanyId = '';
    for (final entry in companies.entries) {
      if (entry.value['name'] == selectedCompany) {
        selectedCompanyId = entry.key;
        break;
      }
    }

    // Retrieve the correct company password
    String correctCompanyPassword = '';
    if (companies.containsKey(selectedCompanyId)) {
      correctCompanyPassword = companies[selectedCompanyId]['companyPassword'];
    }

    // Check if the entered company password matches the correct one
    if (enteredCompanyPassword != correctCompanyPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nepravilno geslo podjetja'),
        ),
      );
      return; // Don't proceed with user registration
    }
    String capitalize(String input) {
      if (input.isEmpty) {
        return input;
      }
      return input[0].toUpperCase() + input.substring(1);
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the generated UID for the user
      String userId = userCredential.user?.uid ?? "";

      if (userId.isNotEmpty) {
        // Push user data with the UID as the key
        DatabaseReference newUserRef = _dbRef.child("users").child(userId);
        newUserRef.set({
          "name": capitalize(name),
          "surname": capitalize(surname),
          "email": email,
          "companyId": selectedCompanyId,
          "adminPermission": false,
          "active": false // Save the selected company ID
        });

        // User data saved successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uporabnik shranjen v sistem!'),
          ),
        );
      }
    } catch (error) {
      // Handle errors here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Napaka pri registraciji uporabnika: $error'),
        ),
      );
    }

    // Clear the input fields
    nameController.clear();
    surnameController.clear();
    emailController.clear();
    passwordController.clear();
    companyPasswordController.clear();
    companySearchController.clear();
  }
}
