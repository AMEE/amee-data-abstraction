# Copyright (C) 2008-2012 AMEE UK Ltd. - http://www.amee.com
# Released as Open Source Software under the BSD 3-Clause license. See LICENSE.txt for details.

namespace :amee do

  namespace :calculations do

    # Performs application setup
    desc 'Regenerates a lock file for a specified calculations config file. Run as: rake "amee:calculations:lock[<file>]"'
    task :lock, [:file] => [:environment] do |t, args|
      AMEE::DataAbstraction::CalculationSet.regenerate_lock_file(args[:file])
    end

    # Performs application setup
    desc 'Regenerates all locks files. Run as: rake "amee:calculations:lock_all"'
    task :lock_all => [:environment] do |t, args|
      $sheet_types.each_key do |key|
        AMEE::DataAbstraction::CalculationSet.regenerate_lock_file(key.to_s)
      end
    end

  end

end