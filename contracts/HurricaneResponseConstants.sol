/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description	Events and Constants
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock
 *
 * Hurricane Response with Underwriting and Payout
 * Modified work
 *
 * @copyright (c) 2018 Joel Martínez
 * @author Joel Martínez
 */


pragma solidity ^0.4.11;


contract HurricaneResponseConstants {
  /*
  * General events
  */
  event LogPolicyApplied(
    uint _policyId,
    address _customer,
    bytes32 _market,
    uint ethPremium
  );
  event LogPolicyAccepted(
    uint _policyId,
    uint _statistics0,
    uint _statistics1,
    uint _statistics2,
    uint _statistics3,
    uint _statistics4,
    uint _statistics5
  );
  event LogPolicyPaidOut(
    uint _policyId,
    uint ethAmount
  );
  event LogPolicyExpired(
    uint _policyId
  );
  event LogPolicyDeclined(
    uint _policyId,
    bytes32 strReason
  );
  event LogPolicyManualPayout(
    uint _policyId,
    bytes32 strReason
  );
  event LogSendFunds(
    address _recipient,
    uint8 _from,
    uint ethAmount
  );
  event LogReceiveFunds(
    address _sender,
    uint8 _to,
    uint ethAmount
  );
  event LogSendFail(
    uint _policyId,
    bytes32 strReason
  );
  event LogOraclizeCall(
    uint _policyId,
    bytes32 hexQueryId,
    string _oraclizeUrl
  );
  event LogOraclizeCallback(
    uint _policyId,
    bytes32 hexQueryId,
    string _result,
    bytes hexProof
  );
  event LogSetState(
    uint _policyId,
    uint8 _policyState,
    uint _stateTime,
    bytes32 _stateMessage
  );
  event LogExternal(
    uint256 _policyId,
    address _address,
    bytes32 _externalId
  );

  /*
  * General constants
  */

  // minimum premium to cover costs
  uint constant MIN_PREMIUM = 50 finney;
  // maximum premium
  uint constant MAX_PREMIUM = 1 ether;
  // maximum payout
  uint constant MAX_PAYOUT = 1100 finney;

  uint constant MIN_PREMIUM_EUR = 1500 wei;
  uint constant MAX_PREMIUM_EUR = 29000 wei;
  uint constant MAX_PAYOUT_EUR = 30000 wei;

  uint constant MIN_PREMIUM_USD = 1700 wei;
  uint constant MAX_PREMIUM_USD = 34000 wei;
  uint constant MAX_PAYOUT_USD = 35000 wei;

  uint constant MIN_PREMIUM_GBP = 1300 wei;
  uint constant MAX_PREMIUM_GBP = 25000 wei;
  uint constant MAX_PAYOUT_GBP = 270 wei;

  // maximum cumulated weighted premium per risk
  uint constant MAX_CUMULATED_WEIGHTED_PREMIUM = 60 ether;
  // 1 percent for DAO, 1 percent for maintainer
  uint8 constant REWARD_PERCENT = 2;
  // relayer percent
  // reserve for tail risks
  uint8 constant RESERVE_PERCENT = 1;

  // Hardcoded URL, should be mocked or used as a placeholder
  /* string constant ORACLIZE_RATINGS_BASE_URL =
    "xml(https://aviationweather.gov/adds/dataserver_current/httpparam?dataSource=tafs&requestType=retrieve&format=xml&stationString=";
  string constant ORACLIZE_RATINGS_QUERY =
    "&hoursBeforeNow=4).xpath(//TAF[1]/forecast[1]/wind_speed_kt/text())"; */
  string constant ORACLIZE_RATINGS_BASE_URL =
    "json(https://api.weather.gov/stations/";
  string constant ORACLIZE_RATINGS_QUERY =
    "/observations?limit=1).features[0].properties.windSpeed.value";

  // gas Constants for oraclize
  uint constant ORACLIZE_GAS = 1000000;
}