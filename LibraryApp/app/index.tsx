import React, {useState} from 'react';
import {Text, TextInput, View} from 'react-native';

export default function Index() {
  return (
    <View style={{flex:1, backgroundColor:'aliceblue'}}>
      <Text style ={{fontSize: 30}}>Sign in</Text>
    <TextInput
      style={{
      height: 40,
      borderColor: 'gray',
      backgroundColor: 'black',
      borderWidth: 1,
      }}
      placeholder="email"
    />

<TextInput
      style={{
      height: 40,
      borderColor: 'gray',
      backgroundColor: 'black',
      borderWidth: 1,
      }}
      placeholder="password"
    />

    </View>
  );
}
