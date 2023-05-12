import TrieMap "mo:base/TrieMap";
import Trie "mo:base/Trie";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Principal "mo:base/Principal";

import Account "Account";
import BootcampLocalActor "BootcampLocalActor";

actor class MotoCoin() {
  public type Account = Account.Account;

  stable var coinData = {
    name : Text = "MotoCoin";
    symbol : Text = "MOC";
    var supply : Nat = 0;
  };

  var ledger = TrieMap.TrieMap<Account, Nat>(Account.accountsEqual, Account.accountsHash);

  public query func name() : async Text {
    return coinData.name;
  };

  public query func symbol() : async Text {
    return coinData.symbol;
  };

  public func totalSupply() : async Nat {
    return coinData.supply;
  };

  public query func balanceOf(account : Account) : async (Nat) {
    let usrAccount : ?Nat = ledger.get(account);

    switch (usrAccount) {
      case(null) { return 0 };
      case(?accnt) {
        return accnt;
      };
    };
  };

  public shared ({ caller }) func transfer( from : Account, to : Account, amount : Nat ) : async Result.Result<(), Text> {
    let xAccount : ?Nat = ledger.get(from);

    switch (xAccount) {
      case(null) { 
        return #err ("Tú saldo no es suficiente: " # coinData.name ); 
      };

      case(?xActBalance) {
        if (xActBalance < amount) {
          return #err ("Tú saldo no es suficiente: " # coinData.name ); 
        };

        ignore ledger.replace(from, xActBalance - amount);

        let xTargetAccount : ?Nat = ledger.get(to);
        switch (xTargetAccount) {
          case(null) {
            ledger.put(to, amount);
            return #ok ()
          };

          case(?xTgtBalance) {
            ignore ledger.replace(to, xTgtBalance + amount);
            return #ok ()
          }
        };
      };
    };
  };

  private func addBalance(wallet : Account, amount : Nat) : async () {
    let xAccount : ?Nat = ledger.get(wallet);

    switch (xAccount) {
      case(null) { 
        ledger.put(wallet, amount);
        
        return ();
      };

      case(?xActBalance) {
        ignore ledger.replace(wallet, xActBalance + amount);

        return ();
      };
    }
  };

  public func airdrop() : async Result.Result<(), Text> {
    try {
      var students : [Principal] = await BootcampLocalActor.BootcampLocalActor.getAllStudentsPrincipal();

      for (student in students.vals()) {
        var studentAccount = {owner = student; subaccount = null};
        await addBalance(studentAccount, 100);
        coinData.supply += 100;
      };

      return #ok ();
    } catch (e) {
      return #err "Algo salió mal";
    };
  };
};