import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Float "mo:base/Float";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";

actor {
  type Option = {
    id : Nat;
    text : Text;
  };

  type Poll = {
    id : Nat;
    question : Text;
    options : Buffer.Buffer<Option>;
    votes : HashMap.HashMap<Nat, Nat>;
  };

  var polls = Buffer.Buffer<Poll>(0);

  public func createPoll(question : Text) : async Nat {
    let pollId = polls.size();
    let newPoll : Poll = {
      id = pollId;
      question = question;
      options = Buffer.Buffer<Option>(0);
      votes = HashMap.HashMap<Nat, Nat>(10, Nat.equal, Hash.hash);
    };
    polls.add(newPoll);
    pollId;
  };

  public func addOption(pollId : Nat, optionText : Text) : async Nat {
    let poll = polls.get(pollId);
    let optionId = poll.options.size();
    let newOption : Option = {
      id = optionId;
      text = optionText;
    };
    poll.options.add(newOption);
    poll.votes.put(optionId, 0);
    optionId;
  };

  public query func getPollDetails(pollId : Nat) : async {
    id : Nat;
    question : Text;
    options : [Option];
  } {
    let poll = polls.get(pollId);
    {
      id = poll.id;
      question = poll.question;
      options = Buffer.toArray(poll.options);
    };
  };

  public func castVote(pollId : Nat, optionId : Nat) : async Bool {
    let poll = polls.get(pollId);
    switch (poll.votes.get(optionId)) {
      case (null) { false };
      case (?currentVotes) {
        poll.votes.put(optionId, currentVotes + 1);
        true;
      };
    };
  };

  public query func getPollResults(pollId : Nat) : async [{
    optionId : Nat;
    optionText : Text;
    votes : Nat;
    percentage : Float;
  }] {
    let poll = polls.get(pollId);
    var totalVotes = 0;
    for (votes in poll.votes.vals()) {
      totalVotes += votes;
    };

    let results = Buffer.Buffer<{
      optionId : Nat;
      optionText : Text;
      votes : Nat;
      percentage : Float;
    }>(0);

    for (option in poll.options.vals()) {
      let votes = switch (poll.votes.get(option.id)) {
        case (null) 0;
        case (?v) v;
      };
      let percentage = if (totalVotes == 0) 0.0 else Float.fromInt(votes) / Float.fromInt(totalVotes) * 100.0;
      results.add({
        optionId = option.id;
        optionText = option.text;
        votes = votes;
        percentage = percentage;
      });
    };

    Buffer.toArray(results);
  };

  public query func getPollStatistics(pollId : Nat) : async {
    totalVotes : Nat;
    numberOfOptions : Nat;
    mostVotedOption : ?{optionId : Nat; optionText : Text; votes : Nat};
  } {
    let poll = polls.get(pollId);
    var totalVotes = 0;
    var mostVotedOption : ?{optionId : Nat; optionText : Text; votes : Nat} = null;

    for ((optionId, votes) in poll.votes.entries()) {
      totalVotes += votes;
      switch (mostVotedOption) {
        case (null) {
          mostVotedOption := ?{
            optionId = optionId;
            optionText = poll.options.get(optionId).text;
            votes = votes;
          };
        };
        case (?currentMost) {
          if (votes > currentMost.votes) {
            mostVotedOption := ?{
              optionId = optionId;
              optionText = poll.options.get(optionId).text;
              votes = votes;
            };
          };
        };
      };
    };

    {
      totalVotes = totalVotes;
      numberOfOptions = poll.options.size();
      mostVotedOption = mostVotedOption;
    };
  };
};