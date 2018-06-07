/**
 * Unit tests for HurricaneResponseNewPolicy
 *
 * @author Christoph Mussenbrock
 * @description t.b.d
 * @copyright (c) 2017 etherisc GmbH
 *
 * Hurricane Response
 * Modified work
 *
 * @copyright (c) 2018 Joel Martínez
 * @author Joel Martínez
 */

/* global artifacts */
/* global contract */
/* global it */
/* global web3 */
/* global assert */
/* global after */

const EventEmitter = require('events')
const Logformatter = require('./logformatter.js')
const testSuite = require('./HurricaneResponseNewPolicy_Suite.js')
// const log = require('../util/logger')

const doTests = [
  '#01', // ETH - no covered hurricane event
  '#02', // USD - no covered hurricane event
  '#03', // USD - covered < 5 miles cat5 hurricane event
  '#04', // USD - covered < 5 miles cat4 hurricane event
  '#05', // USD - covered < 5 miles cat3 hurricane event
  '#06', // USD - covered (5 < cat3 hurricane event < 15 miles)
  '#07' // USD - covered (15 < cat4 hurricane event < 30 miles)
  // '#08', // USD - covered (5 < cat5 hurricane event < 15 miles)
  // '#09' // USD - no covered hurricane event (30 miles > cat5)
]

const logger = new Logformatter(web3)
const EventsSeen = []

const HurricaneResponseController = artifacts.require('HurricaneResponseController')
const HurricaneResponseAccessController = artifacts.require('HurricaneResponseAccessController')
const HurricaneResponseDatabase = artifacts.require('HurricaneResponseDatabase')
const HurricaneResponseLedger = artifacts.require('HurricaneResponseLedger')
const HurricaneResponseNewPolicy = artifacts.require('HurricaneResponseNewPolicy')
const HurricaneResponseUnderwrite = artifacts.require('HurricaneResponseUnderwrite')
const HurricaneResponsePayout = artifacts.require('HurricaneResponsePayout')

contract('HurricaneResponseNewPolicy', (accounts) => {
  const EE = new EventEmitter()
  let timeout

  const eventsHappened = (events) => {
    for (let ev = 0; ev < events.length; ev += 1) {
      // log('Search: ', events[ev].event)
      const ef = EventsSeen.find((elem) => {
        // log('Compare with: ', elem.event)
        if (elem.event !== events[ev].event) {
          // log('Not found.(1)')
          return false
        }
        // log('Found: ', elem.event)
        if (events[ev].args) {
          if (!elem.args) {
            // log('args nicht vorhanden')
            return false
          }
          // log('Compare args: ', elem.args, events[ev].args)
          const args = Object.keys(events[ev].args)
          for (let i = 0; i < args.length; i += 1) {
            // log('>>', arg, elem.args[arg], events[ev].args[arg])
            if (elem.args[args[i]] !== events[ev].args[args[i]]) {
              // log('args: no match', elem.args[arg], events[ev].args[arg])
              return false
            }
          }
        }
        return true
      })

      if (!ef) {
        // log('Not found.(2)')
        return false
      }
    }
    return true
  }

  const context = {
    logger,
    web3,
    eventsHappened,
    accounts,
    defAccount: accounts[1],
    lastState: undefined
  }

  const testOne = (args, index) => {
    it(args.shouldDoSomething, () => {
      const allEvents = []
      const instances = {}

      const logWatcher = (contract) => {
        const allEv = contract.allEvents()
        allEvents.push(allEv)
        allEv.watch((err, log) => {
          if (err) console.log(err)
          EventsSeen.push(log)
          if (logger.formatLog(contract.abi, log)) EE.emit('logEvent', log)
        })
      }

      const cleanup = (message, success) => {
        logger.logLine('Cleanup success: ', `${success} / ${message}`, 'info')
        allEvents.forEach(elem => elem.stopWatching())
        clearTimeout(timeout)
        EE.removeAllListeners('logEvent')
        assert(success, message)
      }

      logger.reset()
      logger.emptyLine(10, 'verbose')
      logger.logLine('Testing', args.shouldDoSomething, 'info')
      EventsSeen.length = 0

      return HurricaneResponseController.deployed()
        .then((instance) => {
          instances.CT = instance
          logWatcher(instance)
          return HurricaneResponseAccessController.deployed()
        })
        .then((instance) => {
          instances.AC = instance
          logWatcher(instance)
          return HurricaneResponseDatabase.deployed()
        })
        .then((instance) => {
          instances.DB = instance
          logWatcher(instance)
          return HurricaneResponseLedger.deployed()
        })
        .then((instance) => {
          instances.LG = instance
          logWatcher(instance)
          return HurricaneResponseNewPolicy.deployed()
        })
        .then((instance) => {
          instances.NP = instance
          logWatcher(instance)
          return HurricaneResponseUnderwrite.deployed()
        })
        .then((instance) => {
          instances.UW = instance
          logWatcher(instance)
          return HurricaneResponsePayout.deployed()
        })
        .then((instance) => {
          instances.PY = instance
          logWatcher(instance)

          logger.emptyLine(5, 'verbose')

          logger.logLine('Controller       Address: ', instances.CT.address, 'verbose')
          logger.logLine('AccessController Address: ', instances.AC.address, 'verbose')
          logger.logLine('Database         Address: ', instances.DB.address, 'verbose')
          logger.logLine('Ledger           Address: ', instances.LG.address, 'verbose')
          logger.logLine('NewPolicy        Address: ', instances.NP.address, 'verbose')
          logger.logLine('Underwrite       Address: ', instances.UW.address, 'verbose')
          logger.logLine('Payout           Address: ', instances.PY.address, 'verbose')

          const policy = args.data(index)

          if (policy.currency > 0) {
            context.defAccount = accounts[3]
          }

          return instances.NP.newPolicy(
            web3.fromAscii(policy.market),
            web3.fromAscii(policy.season),
            web3.fromAscii(policy.latlng),
            policy.currency,
            web3.fromAscii(policy.customerId),
            args.tx(context)
          )
        })
        .then(receipt => new Promise((resolve, reject) => {
          timeout = setTimeout(
            args.timeoutHandler(resolve, reject, context),
            args.timeoutValue
          )
          EE.on('logEvent', args.logHandlerUnderwrite(resolve, reject, context))
        }))
        .then(() => {
          clearTimeout(timeout)
          const policy = args.data(index)
          const tx = args.payoutTx({ ...context, defAccount: accounts[3] })
          delete tx.value
          return instances.PY.schedulePayoutOraclizeCall(
            policy.id,
            policy.riskId,
            0,
            tx
          )
        })
        .then(receipt => new Promise((resolve, reject) => {
          timeout = setTimeout(
            args.timeoutHandler(resolve, reject, context),
            args.timeoutValue
          )
          EE.on('logEvent', args.logHandlerPayout(resolve, reject, context))
        }))
        .then(result => { cleanup(result, true) })
        .catch(error => { cleanup(error, false) })
    })
  }

  doTests.forEach((key, i) => testOne(testSuite.find(testDef => testDef.testId === doTests[i]), i))

  after(async () => {
    if (web3.version.network < 1000) {
      const CT = await HurricaneResponseController.deployed()
      await CT.destructAll({ from: accounts[1], gas: 4700000 })
    }
  })
}) // contract
