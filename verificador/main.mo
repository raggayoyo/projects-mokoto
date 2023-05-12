import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";
import Error "mo:base/Error";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Timer "mo:base/Timer";
import Buffer "mo:base/Buffer";
import Type "Types";
import Ic "Ic";

actor class Verifier() {
  type StudentProfile = Type.StudentProfile;

  let studentProfileStore = HashMap.HashMap<Principal, StudentProfile>(0, Principal.equal, Principal.hash);

  private func isRegistered(p : Principal) : Bool {
    var xProfile : ?StudentProfile = studentProfileStore.get(p);

    switch (xProfile) {
      case null { 
        return false;
      };

      case (?profile) {
        return true
      };
    }
  };

  public shared ({ caller }) func addMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    if (Principal.isAnonymous(caller)) {
      return #err "Debes iniciar sesión"
    };

    if (isRegistered(caller)) {
      return #err ("Ya está registrado (" # Principal.toText(caller) # ") ")
    };

    studentProfileStore.put(caller, profile);
    return #ok ();
  };

  public shared query ({ caller }) func seeAProfile(p : Principal) : async Result.Result<StudentProfile, Text> {
    var xProfile : ?StudentProfile = studentProfileStore.get(p);

    switch (xProfile) {
      case null { 
        return #err ("No hay ningún perfil registrado con está cuenta");
      };

      case (?profile) {
        return #ok profile
      };
    }
  };

  public shared ({ caller }) func updateMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    if (Principal.isAnonymous(caller)) {
      return #err "Debes iniciar sesión"
    };
    
    if (not isRegistered(caller)) {
      return #err ("No está registrado");
    };

    ignore studentProfileStore.replace(caller, profile);

    return #ok ();
  };

  public shared ({ caller }) func deleteMyProfile() : async Result.Result<(), Text> {
    if (Principal.isAnonymous(caller)) {
      return #err "Debes iniciar sesión"
    };
    
    if (not isRegistered(caller)) {
      return #err ("No está registrado");
    };

    studentProfileStore.delete(caller);

    return #ok ();
  };

  public type TestResult = Type.TestResult;
  public type TestError = Type.TestError;

  public func test(canisterId : Principal) : async TestResult {
    let calculatorInterface = actor(Principal.toText(canisterId)) : actor {
      reset : shared () -> async Int;
      add : shared (x : Nat) -> async Int;
      sub : shared (x : Nat) -> async Int;
    };

    try {
      let x1 : Int = await calculatorInterface.reset();
      if (x1 != 0) {
        return #err(#UnexpectedValue("Despues de un reinicio, el contador debe ser 0"));
      };

      let x2 : Int = await calculatorInterface.add(2);
      if (x2 != 2) {
        return #err(#UnexpectedValue("Al sumar 0 + 2, el contador debería ser 2"));
      };

      let x3 : Int = await calculatorInterface.sub(2);
      if (x3 != 0) {
        return #err(#UnexpectedValue("Al restar 2 - 2, el contador debería ser 0"));
      };

      return #ok ();
    } catch (e) {
      return #err(#UnexpectedError("Algo salió mal"));
    } 
  };

  public func verifyOwnership(canisterId : Principal, p : Principal) : async Bool {
    try {
      let controllers = await Ic.getCanisterControllers(canisterId);

      var isOwner : ?Principal = Array.find<Principal>(controllers, func prin = prin == p);
      
      if (isOwner != null) {
        return true;
      };

      return false;
    } catch (e) {
      return false;
    }
  };

  public shared ({ caller }) func verifyWork(canisterId : Principal, p : Principal) : async Result.Result<(), Text> {
    try {
      let isApproved = await test(canisterId); 

      if (isApproved != #ok) {
        return #err("Su proyecto no ha pasado la prueba");
      };

      let isOwner = await verifyOwnership(canisterId, p); 

      if (not isOwner) {
        return #err ("El ID del propietario no coincide con el trabajo");
      };

      var xProfile : ?StudentProfile = studentProfileStore.get(p);

      switch (xProfile) {
        case null { 
          return #err("El ID recibido no coincide con ningún estudiante");
        };

        case (?profile) {
          var updatedStudent = {
            name = profile.name;
            graduate = true;
            team = profile.team;
          };

          ignore studentProfileStore.replace(p, updatedStudent);
          return #ok ();      
        }
      };
    } catch(e) {
      return #err("No se puede verificar el proyecto");
    }
  };
};
