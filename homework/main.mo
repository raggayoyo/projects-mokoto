import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Text "mo:base/Text";

actor HomeworkDiary {
    // Variables
    public type Time = Time.Time;
    public type Homework = {
        title : Text;
        description : Text;
        dueDate : Time;
        completed : Bool;
    };
    var homeworkDiary = Buffer.Buffer<Homework>(0);

    // Functions
    public func addHomework(homework: Homework) : async Nat {
        homeworkDiary.add(homework);
        return (homeworkDiary.size()-1);
    };

    public query func getHomework(homeworkId : Nat) : async Result.Result<Homework, Text> {
        if (homeworkDiary.size() <= homeworkId) {
            return #err "El ID de tarea solicitado, no se encuentra en el diario.";
        };
        var resultid = homeworkDiary.get(homeworkId);
        return #ok resultid;
    };

    public func updateHomework(homeworkId : Nat, homework : Homework) : async Result.Result<(), Text> {
        if (homeworkDiary.size() <= homeworkId) {
            return #err "El ID de tarea solicitado, no se encuentra en el diario.";
        };
        homeworkDiary.put(homeworkId, homework);
        return #ok ()
    };
    
    public func markAsCompleted(homeworkId : Nat) : async Result.Result<(), Text> { 
        if (homeworkDiary.size() <= homeworkId) {
            return #err "El ID de tarea solicitado, no se encuentra en el diario.";
        };
        var findhomework : Homework = homeworkDiary.get(homeworkId);
        var completedhomework : Homework = {
            title = findhomework.title;
            description = findhomework.description;
            dueDate = findhomework.dueDate;
            completed = true;
        };
        homeworkDiary.put(homeworkId, completedhomework);
        return #ok ()
    };

    public func deleteHomework(homeworkId : Nat) : async Result.Result<(), Text> {
        if (homeworkDiary.size() <= homeworkId) {
            return #err "El ID de tarea solicitado, no se encuentra en el diario.";
        };
        var x = homeworkDiary.remove(homeworkId);
        return #ok ()
    };

    public query func getAllHomework() : async [Homework] {
        return Buffer.toArray<Homework>(homeworkDiary);
    };

    public query func getPendingHomework() : async [Homework] {
        var pendingHomework = Buffer.clone(homeworkDiary);
        pendingHomework.filterEntries(func(_, listHomework) = listHomework.completed == false);
        return Buffer.toArray<Homework>(pendingHomework);
    };

    public query func searchHomework(searchTerm : Text) : async [Homework] {
        var search = Buffer.clone(homeworkDiary);   
        search.filterEntries(func(_, listHomework) = Text.contains(listHomework.title, #text searchTerm) or Text.contains(listHomework.description, #text searchTerm));
        return Buffer.toArray<Homework>(search);
    };
};