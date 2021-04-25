import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:snapping_sheet/snapping_sheet.dart';

// void main() => runApp(MyApp());

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}
bool userIn = false;

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
            body: Center(
                child: Text(snapshot.error.toString(),
                    textDirection: TextDirection.ltr)));
      }
      if (snapshot.connectionState == ConnectionState.done) {
        return MyApp();
      }
      return Center(child: CircularProgressIndicator());
        },
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',
      theme: ThemeData(
        primaryColor: Colors.red,
      ),
      home: RandomWords(),
    );
  }
}


class RandomWords extends StatefulWidget {
  @override
  _RandomWordsState createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[];                 // NEW
  // final _suggestions = generateWordPairs().take(10).toList();
  final _saved = <WordPair>{};     // NEW
  final _biggerFont = const TextStyle(fontSize: 18); // NEW
  // bool userIn = false;

  void _showDelSnackBar(){
    final snackBar = SnackBar(content: Text('Deletion is not implemented yet'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _LoginFunc() {
    // setState(() {
    //   userIn = true;
    // });
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Login(),
      ),
    );
  }

  void _LogOutFunc() async{
    // print('loooooooooooooooog ouuuuuuut');
    setState(() {
      userIn = false;
    });
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RandomWords()));
  }
  //
  // void _SignUpFunc() async{
  //   var result = FirebaseAuth.instance.createUserWithEmailAndPassword(email: _loginEmailController, password: _loginPasswordController)
  //
  // }

  void _pushSaved() {
    Navigator.of(context).push(
        MaterialPageRoute<void>(
          // NEW lines from here...
            builder: (BuildContext context) {
              // print('i am hereeeeeeeeeeeeeeeee  1');
              // print(_saved);
              // print(_saved.length == 0);
              // if(_saved.length == 0){
              //   return Container();
              // }
              final tiles = _saved.map(
                    (WordPair pair) {
                  return ListTile(
                    title: Text(
                      pair.asPascalCase,
                      style: _biggerFont,
                    ),
                    // trailing:  IconButton(icon: Icon(Icons.delete_outline,color: Colors.red), onPressed: _showDelSnackBar),
                    trailing:  Icon(Icons.delete_outline,color: Colors.red),
                    onTap : () {
                      setState(() {
                        _saved.remove(pair);
                        print('remooooove');

                      //  TO DO: delete from the firestore

                        if(FirebaseAuth.instance.currentUser != null) {
                          String userId = FirebaseAuth.instance.currentUser!.uid;
                          FirebaseFirestore.instance.collection('users').doc(userId).update(
                              {'suggestions': FieldValue.arrayRemove([pair.asPascalCase])});
                        }
                      });
                    },
                  );
                },
              );

              // List<String> suggCopy = [];
              // if(FirebaseAuth.instance.currentUser != null) {
              //   FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get().then((documentSnapshot) async =>
              //   suggCopy = documentSnapshot.data()![FirebaseAuth.instance.currentUser!.uid]);
              //
              //   print("the user has prev suggs !!, suggCopy.length =");
              //   print(suggCopy.length);
              //   String userId = FirebaseAuth.instance.currentUser!.uid;
              //   for(int i=0 ; i<suggCopy.length ; i++) {
              //     print("add the prev suggs !!");
              //     final beforeCapitalLetter = RegExp(r"(?=[A-Z])");
              //     var parts = suggCopy[i].split(beforeCapitalLetter);
              //     if (parts.isNotEmpty && parts[0].isEmpty) parts = parts.sublist(1);
              //
              //     _saved.add(WordPair(parts[0], parts[1]));
              //
              //   }
              // print('suggCopy');
              //   print(suggCopy);
              // }


              var divided = <Widget>[];
              if(tiles.isNotEmpty)
                divided = ListTile.divideTiles(
                  context: context,
                  tiles: tiles,
                ).toList();

              return Scaffold(
                appBar: AppBar(
                  title: Text('Saved Suggestions'),
                ),
                body: divided.isNotEmpty ? ListView(children:  divided ) : Center(child: Text('No Saved Suggestions')),
              );
            }, // ...to here.
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // return Container();
    // final wordPair = WordPair.random();      // NEW
    // return Text(wordPair.asPascalCase);      // NEW
    return Scaffold (                     // Add from here...
      appBar: AppBar(
        title: Text('Startup Name Generator'),
        actions: [
          IconButton(icon: Icon(Icons.favorite), onPressed: _pushSaved),
          IconButton(icon: userIn ?  Icon(Icons.exit_to_app) : Icon(Icons.login),
              onPressed: userIn ? _LogOutFunc : _LoginFunc)
        ],
      ),
      body: _buildSuggestions(),
    );                                      // ... to here.
  }

  Widget _buildSuggestions() {
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        // The itemBuilder callback is called once per suggested
        // word pairing, and places each suggestion into a ListTile
        // row. For even rows, the function adds a ListTile row for
        // the word pairing. For odd rows, the function adds a
        // Divider widget to visually separate the entries. Note that
        // the divider may be difficult to see on smaller devices.
        itemBuilder: (BuildContext _context, int i) {
          // Add a one-pixel-high divider widget before each row
          // in the ListView.
          if (i.isOdd) {
            return Divider();
          }

          // The syntax "i ~/ 2" divides i by 2 and returns an
          // integer result.
          // For example: 1, 2, 3, 4, 5 becomes 0, 1, 1, 2, 2.
          // This calculates the actual number of word pairings
          // in the ListView,minus the divider widgets.
          final int index = i ~/ 2;
          // If you've reached the end of the available word
          // pairings...
          if (index >= _suggestions.length) {
            // ...then generate 10 more and add them to the
            // suggestions list.
            _suggestions.addAll(generateWordPairs().take(10));
          }
          return _buildRow(_suggestions[index]);
        }
    );
  }

  Widget _buildRow(WordPair pair) {
    final alreadySaved = _saved.contains(pair);  // NEW
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(   // NEW from here...
        alreadySaved ? Icons.favorite : Icons.favorite_border,
        color: alreadySaved ? Colors.red : null,
      ),
      onTap: () {      // NEW lines from here...
        setState(() {
          if (alreadySaved) {
            _saved.remove(pair);

            if(FirebaseAuth.instance.currentUser != null) {
              String userId = FirebaseAuth.instance.currentUser!.uid;
              FirebaseFirestore.instance.collection('users').doc(userId).update(
                  {'suggestions': FieldValue.arrayRemove([pair.asPascalCase])});
            }

          } else {
            _saved.add(pair);

            if(FirebaseAuth.instance.currentUser != null) {
              String userId = FirebaseAuth.instance.currentUser!.uid;
              FirebaseFirestore.instance.collection('users').doc(userId).update(
                  {'suggestions': FieldValue.arrayUnion([pair.asPascalCase])});
            }
    }
        });
      //TO DO:
      //  if the user is logged in then update his database
      //      var suggList=_saved.toList();
      //      List<String> suggCopy = [];
      //      for(int i=0 ; i<suggList.length ; i++) {
      //        suggCopy.add(suggList[i].toString());
      //      }
      //   if(FirebaseAuth.instance.currentUser != null){
      //
      //     String userId= FirebaseAuth.instance.currentUser!.uid;
      //     // CollectionReference suggs = FirebaseFirestore.instance.collection('users');
      //     // suggs.doc(userId).update(<String,dynamic>{userId : suggCopy});
      //
      //     FirebaseFirestore.instance.collection('users').doc(userId).update(
      //         {'suggestions' : FieldValue.arrayUnion([pair.asPascalCase])});
      //
      //   }else{
      //     return;
      //   }
      },
    );
  }
}


class Login extends StatefulWidget{
  @override
  _Login createState() => _Login();
}

class _Login extends State<Login> {
  //added for HW_2
  bool userInProcessOfLogin = false;
  // FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  TextEditingController _loginEmailController = TextEditingController();
  TextEditingController _loginPasswordController = TextEditingController();
  TextEditingController _loginConfPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Login'),
          centerTitle: true,
        ),
        body: ListView(children: <Widget>[
          Container(
              padding: EdgeInsets.all(20),
              child: Text(
                'Welcome to Startup Names Generator , please log in below',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 15
                ),
              )),
          Container(
              padding: EdgeInsets.all(10),
              child: TextField(
                decoration: InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Email'),
                obscureText: false,
                controller: _loginEmailController,
              )),
          Container(
              padding: EdgeInsets.all(20),
              child: TextField(
                decoration: InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Password'),
                obscureText: true,
                controller: _loginPasswordController,
              )
          ),
          ElevatedButton(onPressed: () async {//replaced for HW_2: _showLoginSnackBar,

            try{
                  if(userInProcessOfLogin == false){
                  setState(() {
                    userInProcessOfLogin = true;
                  });
                  var result = await   FirebaseAuth.instance.signInWithEmailAndPassword(email: _loginEmailController.text, password: _loginPasswordController.text);
                 // print("result=");
                 // print(result);
                  if(result != null) {
                    setState(() {
                      userIn = true;
                    });
                     Navigator.of(context).push(
                     MaterialPageRoute<void>(builder: (_) => RandomWords(),),
                   );
                    // fixme: if there is no database for the user, make one
                    // FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).set(<String,dynamic>{FirebaseAuth.instance.currentUser!.uid : null});
                  }
                  /*else{
                   var snackBar = SnackBar(content: Text('There was an error logging into the app'));
                   ScaffoldMessenger.of(context).showSnackBar(snackBar);

                 }*/
                  userInProcessOfLogin = false;

                  print("I get a !!!!!!!!!!!!!!!!!!!!!!");
                  List<String> suggCopy = [];
                  await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get().then((documentSnapshot) async =>
                  suggCopy = documentSnapshot.data()![FirebaseAuth.instance.currentUser!.uid]);
                  print(suggCopy);

                  print('ylaaaaaaaaaaaa');
                  FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).set(<String,dynamic>{FirebaseAuth.instance.currentUser!.uid : suggCopy});
                }else{
                  print('the Login button disabled!!');
                  // userInProcessOfLogin = true;  # Fixme
            }
            } on FirebaseAuthException catch(e){
                var snackBar = SnackBar(content: Text('There was an error logging into the app'));
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                userInProcessOfLogin = false;
               }
            },
              child: Text('Log in'),
              style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.red),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                          borderRadius:  new BorderRadius.circular(30.0),
                      side: BorderSide(color: Colors.red)
                      ))
              )
          ),
          Container(
              // height: 40,
              decoration: BoxDecoration( borderRadius: BorderRadius.all(Radius.circular(10))),
              padding: EdgeInsets.fromLTRB(2, 0, 1, 0),
              child:  userInProcessOfLogin ? Container() : ElevatedButton(
                  style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius:  new BorderRadius.circular(30),
                      )
                   )),
                  child: Container(child: Text('New user? Click to sign up')),
                  onPressed: () async {
                      // showModalBottomSheet(
                          var result = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _loginEmailController.text, password: _loginPasswordController.text);
                          showModalBottomSheet(context: context,
                              builder: (BuildContext context) {
                                return Container(
                                    // child: Text("Edit me")
                                    height: 140,
                                    child :ListView(children: <Widget>[
                                      Container(
                                          alignment: Alignment.center,
                                          child: Text('Please confirm your password below:',
                                          )),
                                      Container(
                                          child: Text('password',style: TextStyle(color: Colors.red)
                                          )),
                                      Container(
                                        child: TextField(
                                          obscureText: true,
                                          controller: _loginConfPasswordController,
                                          decoration: InputDecoration(
                                            border: UnderlineInputBorder(),
                                            // hoverColor: Colors.red,
                                            // focusColor: Colors.red
                                          ),),
                                      ),
                                      Container(
                                          padding: EdgeInsets.fromLTRB(150, 10, 150, 10),
                                          child : ElevatedButton(
                                            child:Text('Confirm',style: TextStyle(color: Colors.white)),
                                            style: ButtonStyle(
                                                backgroundColor: MaterialStateProperty.all<Color>(Colors.green)),
                                            onPressed: (){
                                                bool samePass = (_loginPasswordController.text == _loginConfPasswordController.text);
                                              if(samePass){ //success
                                                print("almost done!");
                                                Navigator.of(context).push(
                                                  MaterialPageRoute<void>(
                                                    builder: (_) => Login(),
                                                  ),
                                                );
                                              }else{
                                                _showWrongPasswSnackBar();
                                                print("wrong password");

                                              }
                                            },
                                          ))
                                    ])

                                );});

                          print("the result of signup is:");
                          print(result);
                          List<String> suggCopy = [];
                          await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).set(<String,dynamic>{FirebaseAuth.instance.currentUser!.uid : suggCopy});
                    // );

                  },
              ))
        ]),
    );
}

  // void _showLoginSnackBar(){
  //   final snackBar = SnackBar(content: Text('Login is not implemented yet'));
  //   ScaffoldMessenger.of(context).showSnackBar(snackBar);
  // }
void _showWrongPasswSnackBar(){
  final snackBar = SnackBar(content: Text('Wrong Password'));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

}

class _SignUpFunc {
}
