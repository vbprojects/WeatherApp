

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:weather_icons/weather_icons.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}


Future<http.Response> fetchData() async{
  return http.get('https://geocoding.geo.census.gov/geocoder/locations/address?street=2427+Dakota+Lakes+Drive&zip=20171&benchmark=Public_AR_Current&format=json');
}

class WeatherItem{
  String name;
  String temp;
  String windSpeed;
  String windDir;
  String shortForecast;
  String detailedForecast;
  String icon;
  WeatherItem(this.name, this.temp, this.windSpeed, this.windDir, this.shortForecast, this.detailedForecast, this.icon);
  String toString(){
    return this.icon;
  }
}


class _MyHomePageState extends State<MyHomePage> {
  bool zipcode = false;
  bool gotInfo = false;

  double WIDTH = 0;
  double HEIGHT = 0;
  String zip;
  Widget content;
  Widget weather1;
  Widget weather2;
  Widget weather;
  TextFormField zipInput;
  List<WeatherItem> witems;
  List<Widget> weathers;
  String state;
  String city;
  final myController = TextEditingController();
  Map<String, IconData> iconMap;


  void makeIconMap(){
    iconMap = Map<String, IconData>();
    iconMap["Storm"] = WeatherIcons.day_thunderstorm;
    iconMap["Cloudy"] = WeatherIcons.cloudy;
    iconMap["Sunny"] = WeatherIcons.day_sunny;
    iconMap["Clear"] = WeatherIcons.night_clear;
    iconMap["rain"] = WeatherIcons.day_rain;
    iconMap["snow"] = WeatherIcons.day_snow;
  }

  void get_data() async{
    String streetAndZip = myController.text;
    String street = streetAndZip.substring(0, streetAndZip.indexOf(","));
    String zip = streetAndZip.substring(streetAndZip.indexOf(",")+1,streetAndZip.length).trim();
    print(zip.trim());
    street = street.trim().replaceAll(" ", "+");
    print(street);
    String firstUrl = 'https://geocoding.geo.census.gov/geocoder/locations/address?street=${street}&zip=${zip}&benchmark=Public_AR_Current&format=json';
    final response = await http.get(firstUrl);
    Map<String, dynamic> weather_data = jsonDecode(response.body);

    double xcord = weather_data["result"]['addressMatches'][0]["coordinates"]['x'];
    double ycord = weather_data["result"]['addressMatches'][0]["coordinates"]['y'];

    String cityT = weather_data["result"]['addressMatches'][0]["addressComponents"]['city'];
    String stateT = weather_data["result"]['addressMatches'][0]["addressComponents"]['state'];

    final wresponse = await http.get("https://api.weather.gov/points/${ycord},${xcord}");

    Map<String, dynamic> weather_d = jsonDecode(wresponse.body);

    String url = weather_d["properties"]["forecast"];
    final fresponse = await http.get(url);
    Map<String, dynamic> forecast = jsonDecode(fresponse.body);
    List<WeatherItem> temp = [];
    forecast["properties"]["periods"].forEach(
        (element){
          String shortDesc = element["shortForecast"];
          int sinDex = shortDesc.indexOf("then");
          shortDesc = shortDesc.substring(0, sinDex != -1 ? sinDex : shortDesc.length);
          int chncDesc = shortDesc.indexOf("Chance");
          String iconHash = shortDesc;
          if(chncDesc != -1){
            iconHash = shortDesc.substring(chncDesc+"Chance".length, shortDesc.length);
            shortDesc = "Chance of" + iconHash;
          }
          temp.add(WeatherItem(element["name"], element["temperature"], element["windSpeed"], element["windDirection"], shortDesc, element["detailedForecast"], iconHash));
        });
    setState(() {
      witems = temp;
      gotInfo = true;
      city = cityT;
      state = stateT;
    });
  }

  void changeZip(){
    setState(() {
      zipcode = !zipcode;
    });
    get_data();
  }

  @override
  Widget build(BuildContext context) {
    makeIconMap();
    this.HEIGHT = MediaQuery.of(context).size.height;
    this.WIDTH = MediaQuery.of(context).size.width;


    Widget content;
    zipInput = TextFormField(
      controller: myController,
      decoration: const InputDecoration(
        hintText: 'STREET, ZIPCODE',
      ),
    );
    content = AnimatedOpacity(
      opacity: zipcode ? 0 : 1,
      duration: Duration(seconds: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Center(
            child: SizedBox(
              width: WIDTH*.4,
              child: zipInput,
            ),
          ),
          SizedBox(
            width: WIDTH*.1,
            child: FlatButton(
              onPressed: changeZip,
              child: Icon(Icons.arrow_forward),
              color: Colors.redAccent,
            ),
          )
        ],
      ),
    );
    if(!gotInfo){
      weathers = [RaisedButton(
        onPressed: get_data,
        color: Colors.black,)];
    }
    else{
      weathers = [];
      witems.forEach((element) {
        weathers.add(
            AnimatedContainer(
              duration: Duration(milliseconds: 100),
              height: WIDTH*.35,
              width: WIDTH*.35,
              color: Colors.blueAccent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Center(child: Text(element.name,style: TextStyle(fontSize: WIDTH*.04),)),
                  Icon(
                    element.shortForecast.indexOf("Thunderstorms") != -1 ? iconMap["Storm"] : element.shortForecast.indexOf("Sunny") != -1 ? iconMap["Sunny"] : element.shortForecast.indexOf("cloudy") != -1 ?
                        iconMap["Cloudy"] : element.shortForecast.indexOf("Rain") != -1 ? iconMap["rain"] : element.shortForecast.indexOf("clear") != -1 ? iconMap["Clear"] :
                    element.shortForecast.indexOf("snow") != -1 ? iconMap["snow"] : iconMap["Sunny"],
                    size: WIDTH*.1,
                  ),
                  SizedBox(height: HEIGHT*.0025,),
                  Center(child: Text("${element.temp}°F", style: TextStyle(fontSize: WIDTH*.03),)),
                  Center(child: Text(element.shortForecast, style: TextStyle(fontSize: WIDTH*(.02)),)),
                ],
              ),
            )
        );
      });
    }
    weather = Padding(
      padding: EdgeInsets.all(HEIGHT*.03),
      child: Wrap(
          alignment: WrapAlignment.center,
          spacing: WIDTH*.03,
          runSpacing: HEIGHT*.03,
          children: weathers
      ),
    );
    return Scaffold(
      body: Center(
        child: AnimatedContainer(
          width: zipcode ? WIDTH*.9 : WIDTH*.6,
          height: zipcode ? HEIGHT*.9 : HEIGHT*.1,
          color: zipcode ? Colors.grey : Colors.red,
          duration: Duration(milliseconds: 100),
          curve: Curves.fastOutSlowIn,
          child: !zipcode ? content : Scaffold(
              appBar: AppBar(
                title: Text("${city}, ${state}"),
              ),
              body: ListView(children: [weather])
          )
        ),
      ),
    );
  }
}
