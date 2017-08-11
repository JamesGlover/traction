# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SequencingRun, type: :model do
  it 'must have an instrument name' do
    expect(build(:sequencing_run, instrument_name: nil)).to_not be_valid
  end

  it '#experiment_name is the id' do
    sequencing_run = create(:sequencing_run)
    expect(sequencing_run.experiment_name).to eq(sequencing_run.id)
  end

  it 'removes any flowcells which do not have a work order before validation' do
    sequencing_run = create(:sequencing_run,
                            flowcells_attributes: build_nested_attributes_for(
                              build_attributes_list_for(:flowcell, 3, 'sequencing_run_id') +
                              build_attributes_list_for(:flowcell, 2, 'sequencing_run_id',
                                                        'work_order_id')
                            ))
    expect(sequencing_run.flowcells.count).to eq(3)
  end

  it 'ensures that the work order is not spread across more flowcells than have been requested' do
    work_order = create(:work_order_for_sequencing, number_of_flowcells: 3)
    expect(build(:sequencing_run, flowcells: build_list(
      :flowcell, 5, work_order: work_order
    ))).to_not be_valid

    work_order = create(:work_order_for_sequencing, number_of_flowcells: 3)
    create(:sequencing_run, flowcells: build_list(
      :flowcell, 2, work_order: work_order
    ))

    expect(build(:sequencing_run, flowcells: build_list(
      :flowcell, 3, work_order: work_order
    ))).to_not be_valid
  end

  it 'ensures that the work orders are in the right state' do
    work_order = create(:work_order, number_of_flowcells: 3)
    expect(build(:sequencing_run, flowcells: build_list(
      :flowcell, 3, work_order: work_order
    ))).to_not be_valid
  end

  it 'can have state' do
    sequencing_run = create(:sequencing_run)
    expect(sequencing_run).to be_pending

    sequencing_run.completed!
    expect(sequencing_run).to be_completed

    sequencing_run.user_terminated!
    expect(sequencing_run).to be_user_terminated

    sequencing_run.instrument_crashed!
    expect(sequencing_run).to be_instrument_crashed

    sequencing_run.restart!
    expect(sequencing_run).to be_restart
  end

  it '#flowcells_by_position will return the flowcells in the correct order' do
    sequencing_run = build(:sequencing_run)
    flowcells = sequencing_run.flowcells_by_position
    expect(flowcells.count).to eq(SequencingRun::MAX_FLOWCELLS)
    expect(flowcells.all?(&:new_record?)).to be_truthy

    flowcell_1 = create(:flowcell, position: 1)
    flowcell_5 = create(:flowcell, position: 5)
    sequencing_run = create(:sequencing_run, flowcells: [flowcell_1, flowcell_5])
    flowcells = sequencing_run.flowcells_by_position
    expect(flowcells.first).to eq(flowcell_1)
    expect(flowcells[1]).to be_new_record
    expect(flowcells[2]).to be_new_record
    expect(flowcells[3]).to be_new_record
    expect(flowcells.last).to eq(flowcell_5)
  end
end