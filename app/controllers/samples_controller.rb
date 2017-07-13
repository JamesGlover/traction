class SamplesController < ApplicationController

  attr_reader :samples

  def index
    @samples = Sample.all
  end

  def edit
    @sample ||= current_resource
  end

  def update
    sample = current_resource
    if sample.update_attributes(sample_params)
      redirect_to samples_path, notice: 'Sample successfully updated'
    else
      render :edit
    end
  end

  protected

  def current_resource
    @current_resource = Sample.find(params[:id]) if params[:id].present?
  end

  def sample_params
    params.require(:sample).permit(:concentration, :fragment_size, :qc_state)
  end

  helper_method :samples

end