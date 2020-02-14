class Role < ActiveRecord::Base
    has_many :users
    validates_uniqueness_of  :name, :rc
    validates_presence_of :name, :rc
    ACTIVITY_TYPES = {:syncall=>1,:messages=>2,:acknowledgements=>3,:testresults=>4,:no5=>'',:usage=>6,:userprofile=>7,:profiledata=>8,:updateuser=>9,:activites=>10,:drm=>11,:devicemessage=>12}
end
