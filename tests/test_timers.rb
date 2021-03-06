# $Id$
#
# Author:: Francis Cianfrocca (gmail: blackhedd)
# Homepage::  http://rubyeventmachine.com
# Date:: 8 April 2006
# 
# See EventMachine and EventMachine::Connection for documentation and
# usage examples.
#
#----------------------------------------------------------------------------
#
# Copyright (C) 2006-07 by Francis Cianfrocca. All Rights Reserved.
# Gmail: blackhedd
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of either: 1) the GNU General Public License
# as published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version; or 2) Ruby's License.
# 
# See the file COPYING for complete licensing information.
#
#---------------------------------------------------------------------------
#
#
#
#

$:.unshift "../lib"
require 'eventmachine'
require 'test/unit'

class TestTimers < Test::Unit::TestCase

  def test_timer_with_block
    x = false
    EventMachine.run {
      EventMachine::Timer.new(0.25) {
        x = true
        EventMachine.stop
      }
    }
    assert x
  end

  def test_timer_with_proc
    x = false
    EventMachine.run {
      EventMachine::Timer.new(0.25, proc {
        x = true
        EventMachine.stop
      })
    }
    assert x
  end

  def test_timer_cancel
    x = true
    EventMachine.run {
      timer = EventMachine::Timer.new(0.25, proc { x = false })
      timer.cancel
      EventMachine::Timer.new(0.5, proc {EventMachine.stop})
    }
    assert x
  end

  def test_periodic_timer
    x = 0
    EventMachine.run {
      EventMachine::PeriodicTimer.new(0.1) do
        x += 1
        EventMachine.stop if x == 4
      end
    }
    assert( x == 4 )
  end

  def test_add_periodic_timer
    x = 0
    EM.run {
      t = EM.add_periodic_timer(0.1) do
        x += 1
        EM.stop  if x == 4
      end
      assert t.respond_to?(:cancel)
    }
  end

  def test_periodic_timer_cancel
    x = 0
    EventMachine.run {
      pt = EventMachine::PeriodicTimer.new(0.25, proc { x += 1 })
      pt.cancel
      EventMachine::Timer.new(0.5) {EventMachine.stop}
    }
    assert( x == 0 )
  end

  def test_add_periodic_timer_cancel
    x = 0
    EventMachine.run {
      pt = EM.add_periodic_timer(0.1) { x += 1 }
      EM.cancel_timer(pt)
      EM.add_timer(0.2) { EM.stop }
    }
    assert( x == 0 )
  end

  def test_periodic_timer_self_cancel
    x = 0
    EventMachine.run {
      pt = EventMachine::PeriodicTimer.new(0.1) {
        x += 1
        if x == 4
          pt.cancel
          EventMachine.stop
        end
      }
    }
    assert( x == 4 )
  end

  def test_restartable_timer
    x = false
    EventMachine.run {
      EventMachine::RestartableTimer.new(0.1) do
        x = true
        EventMachine.stop
      end
    }
    assert x
  end

  def test_add_restartable_timer
    x = false
    EventMachine.run {
      rt = EventMachine.add_restartable_timer(0.1) { x = true }
      assert rt.respond_to?(:restart)
      EventMachine.stop
    }
  end

  def test_restart_restartable_timer
    x = false
    EventMachine.run {
      EventMachine.add_timer(0.4) { x = 1 }
      rt = EventMachine::RestartableTimer.new(0.3) do
        x = true
      end
      EventMachine.add_timer(0.2) { rt.restart }
      EventMachine.add_timer(0.6) { EventMachine.stop }
    }
    assert x == true
  end

  def test_cannot_restart_already_fired_restartable_timer
    x = false
    EventMachine.run {
      rt = EventMachine::RestartableTimer.new(0.1) do
        x = true
      end
      EventMachine.add_timer(0.2) { 
        x = false
        rt.restart
      }
      EventMachine.add_timer(0.4) { EventMachine.stop }
    }
    assert !x
  end

  def test_restartable_timer_cancel
    x = false
    EventMachine.run {
      rt = EventMachine::RestartableTimer.new(0.3) { x = true }
      rt.cancel
      EventMachine::Timer.new(0.1) { EventMachine.stop }
    }
    assert !x
  end

  def test_add_restartable_timer_cancel
    x = false
    EventMachine.run {
      rt = EventMachine.add_restartable_timer(0.2) { x = true }
      EventMachine.cancel_timer(rt)
      EventMachine.add_timer(0.3) { EventMachine.stop }
    }
    assert !x
  end

  def test_cannot_restart_cancelled_restartable_timer
    x = false
    EventMachine.run {
      rt = EventMachine::RestartableTimer.new(0.2) do
        x = true
      end
      rt.cancel
      EventMachine.add_timer(0.1) { 
        x = false
        rt.restart
      }
      EventMachine.add_timer(0.4) { EventMachine.stop }
    }
    assert !x
  end

  # This test is only applicable to compiled versions of the reactor.
  # Pure ruby and java versions have no built-in limit on the number of outstanding timers.
  #
  def test_timer_change_max_outstanding
    defaults = EM.get_max_timers
    EM.set_max_timers(100)

    one_hundred_one_timers = proc { 101.times { EM.add_timer(5) {} } }

    EM.run {
      if EM.library_type == :pure_ruby
        one_hundred_one_timers.call
      elsif EM.library_type == :java
        one_hundred_one_timers.call
      else
        begin
          assert_raises( RuntimeError ) {
            one_hundred_one_timers.call
          }
        rescue Object
          p $!
          assert(false, $!.message)
        end
      end
      EM.stop
    }

    EM.set_max_timers( 101 )

    EM.run {
      one_hundred_one_timers.call
      EM.stop
    }
  ensure
    EM.set_max_timers(defaults)
  end

end
