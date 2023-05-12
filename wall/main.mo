import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import Hash "mo:base/Hash";
import Principal "mo:base/Principal";

actor class StudentWall() {

    public type Answer = (
        description : Text, 
        numberOfVotes : Nat 
    );

    public type Survey = {
        title : Text; 
        answers : [Answer]; 
    };

    public type Content = {
        #Text : Text;
        #Image : Blob;
        #Survey : Survey;
    };

    public type Message = {
        vote : Int;
        content : Content;
        creator : Principal;
    };

	stable var messageIdCount : Nat = 0;

	private func _hashNat(n : Nat) : Hash.Hash = return Text.hash(Nat.toText(n));
	let wall = HashMap.HashMap<Nat, Message>(0, Nat.equal, _hashNat);

	public shared ({ caller }) func writeMessage(c : Content) : async Nat {
		
		let id : Nat = messageIdCount;
		messageIdCount += 1;

		
		var newMessage : Message = {
			vote = 0;
			content = c;
			creator = caller;
		};

		
		wall.put(id, newMessage);

		return id;
	};

	
	public shared query func getMessage(messageId : Nat) : async Result.Result<Message, Text> {
		let messageData : ?Message = wall.get(messageId);

		switch (messageData) {
			case (null) {
				return #err "El mensaje solicitado no existe";
			};
			case (?message) {
				return #ok message;
			};
		};
	};

	public shared ({ caller }) func updateMessage(messageId : Nat, c : Content) : async Result.Result<(), Text> {
		var isAuth : Bool = not Principal.isAnonymous(caller);

		if (not isAuth) {
			return #err "Debes autenticarte para validar que eres el creador del mensaje";
		};

		let messageData : ?Message = wall.get(messageId);

		switch (messageData) {
			case (null) {
				return #err "El mensaje solicitado no existe";
			};
			case (?message) {
				if (message.creator != caller) {
					return #err "Usted no es el creador de este mensaje";
				};

				let updatedMessage : Message = {
					vote = message.vote;
					creator = message.creator;
					content = c;
				};

				wall.put(messageId, updatedMessage);

				return #ok();
			};
		};
	};

	public shared ({ caller }) func deleteMessage(messageId : Nat) : async Result.Result<(), Text> {
		let messageData : ?Message = wall.get(messageId);

		switch (messageData) {
			case (null) {
				return #err "El mensaje solicitado no existe";
			};
			case (?message) {
				if (message.creator != caller) {
					return #err "Usted no es el creador de este mensaje";
				};

				ignore wall.remove(messageId);

				return #ok();
			};
		};

		return #ok();
	};

	public func upVote(messageId : Nat) : async Result.Result<(), Text> {
		let messageData : ?Message = wall.get(messageId);

		switch (messageData) {
			case (null) {
				return #err "El mensaje solicitado no existe";
			};
			case (?message) {
				let updatedMessage : Message = {
					vote = message.vote + 1;
					creator = message.creator;
					content = message.content;
				};

				wall.put(messageId, updatedMessage);

				return #ok();
			};
		};

		return #ok();
	};

	public func downVote(messageId : Nat) : async Result.Result<(), Text> {
		let messageData : ?Message = wall.get(messageId);

		switch (messageData) {
			case (null) {
				return #err "El mensaje solicitado no existe";
			};
			case (?message) {
				let updatedMessage : Message = {
					vote = message.vote - 1;
					creator = message.creator;
					content = message.content;
				};

				wall.put(messageId, updatedMessage);

				return #ok();
			};
		};

		return #ok();
	};

	public func getAllMessages() : async [Message] {
		let messagesBuff = Buffer.Buffer<Message>(0);

		for (msg in wall.vals()) {
			messagesBuff.add(msg);
		};

		return Buffer.toArray<Message>(messagesBuff);
	};

	public func getAllMessagesRanked() : async [Message] {
		let messagesBuff = Buffer.Buffer<Message>(0);

		for (msg in wall.vals()) {
			messagesBuff.add(msg);
		};

		var messages = Buffer.toVarArray<Message>(messagesBuff);

		var size = messages.size();

		if (size > 0) {
			size -= 1;
		};

		for (a in Iter.range(0, size)) {
			var maxIndex = a;

			for (b in Iter.range(a, size)) {
				if (messages[b].vote > messages[a].vote) {
					maxIndex := b;
				};
			};

			let tmp = messages[maxIndex];
			messages[maxIndex] := messages[a];
			messages[a] := tmp;
		};

		return Array.freeze<Message>(messages);
	};
};