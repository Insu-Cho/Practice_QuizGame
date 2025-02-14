// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

//Owner modifier 사용을 위해 라이브러리 추가 
import "@openzeppelin/contracts/access/Ownable.sol";

// Ownable 상속
contract Quiz is Ownable{
    struct Quiz_item {
      uint id;
      string question;
      string answer;
      uint min_bet;
      uint max_bet;
   }
    
// Quizes을 담을 수 있는 mapping 선언
// Quize 현재 퀴즈 정보를  접근 할 수 있도록 mapping 선언
// 현재 상금 정보를 누적할 수 있는 mapping 선언 
    mapping(address => uint256)[] public bets;
    mapping(uint => Quiz_item) public Quizes;
    mapping(address => uint256) public Prize;
    uint public vault_balance;
    uint quiz_current;


    constructor () Ownable(msg.sender) {
        // quiz num 초기화 코드 추가 
        Quiz_item memory q;
        q.id = 1;
        q.question = "1+1=?";
        q.answer = "2";
        q.min_bet = 1 ether;
        q.max_bet = 2 ether;
        addQuiz(q);
        quiz_current = q.id;
    }

// 문자열 비교 함수 추가 
    function isEqual(string memory str1, string memory str2) public pure returns (bool) {
            return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
        }

    function addQuiz(Quiz_item memory q) public onlyOwner {
        Quizes[q.id] = q;
        quiz_current=q.id;
    }

// owner 여부에 따라 다르게 return
    function getAnswer(uint quizId) public view returns (string memory){
        if (msg.sender == owner()) {
            return Quizes[quizId].answer;
        } else {
            return "";
        }
        
    }

// GetQuiz시에는 정답을 공개하면 안됨
    function getQuiz(uint quizId) public view returns (Quiz_item memory) {
        Quiz_item memory temp_quiz = Quizes[quizId];
        temp_quiz.answer="";
        return temp_quiz;
    }

    function getQuizNum() public view returns (uint){
        return Quizes[quiz_current].id;
    }

// betting 금액 최대 최소 검사 배
// bets에 각 퀴즈의 배팅 금액 기록 
    function betToPlay(uint quizId) public payable {
        require((Quizes[quizId].min_bet <= msg.value), "It has exceeded the minimum.");
        require((Quizes[quizId].max_bet >= msg.value),"It has exceeded the maximum.");
        bets.push();
        bets[quizId-1][msg.sender] += msg.value;
        vault_balance -= msg.value;

    }

// Quiz 정답 결과 Return
// 정답이면 vault_balance에 잔고에서 배팅 금액 만큼 제거 후, 상금을 누적한다.
// 오답이면 vault_balance의 배팅 금액 만큼 vault_balance를 증가 시킨다.
    function solveQuiz(uint quizId, string memory ans) public returns (bool) {

        // 정답 시 잔고를 감당 할 수 없으면 미리 revert()
        require((vault_balance>=bets[quizId-1][msg.sender]*2),"vault_balance is lack");
        bool result = isEqual(Quizes[quizId].answer,ans);
        if (result == false) {
            vault_balance +=bets[quizId-1][msg.sender];
        } else {
            vault_balance -=bets[quizId-1][msg.sender]*2;
            Prize[msg.sender]+=bets[quizId-1][msg.sender]*2;  
        }
        bets[quizId-1][msg.sender] = 0;
        
        return result;
    }
    receive() external payable {
        // 이더를 받을 때 실행됨 (데이터 없이 전송된 경우)
        vault_balance+=msg.value;
    }

// 모든 퀴즈의 금액을 합하여 출금 한다.
    function claim() public {
        uint256 claim;
        claim = Prize[msg.sender];
        Prize[msg.sender] = 0;
        (bool s,)=payable(msg.sender).call{value: claim}("");
        require(s, "ETH transfer failed");
        
    }

}
