module Calagator

class SourcesController < Calagator::ApplicationController
  def source
    @source ||= params[:id] ? Source.find(params[:id]) : Source.new
  end

  # POST /import
  def import
    @importer = Source::Importer.new(params.permit![:source])
    respond_to do |format|
      if @importer.import
        format.html { redirect_to events_path, flash: { success: render_to_string(layout: false) } }
        format.xml  { render xml: @importer.source, events: @importer.events }
      else
        format.html { redirect_to new_source_path(url: @importer.source.url), flash: { failure: @importer.failure_message } }
        format.xml  { render xml: @importer.source.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # GET /sources
  def index
    @sources = Source.listing
    respond_to do |format|
      format.html { @sources = @sources.paginate(page: params[:page], per_page: params[:per_page]) }
      format.xml  { render xml: @sources }
    end
  end

  # GET /sources/1
  def show
    source.events(include: :venues) # avoid n+1 query
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: source }
    end
  rescue ActiveRecord::RecordNotFound => error
    flash[:failure] = error.to_s if params[:id] != "import"
    redirect_to new_source_path
  end

  # GET /sources/new
  def new
    source.url = params[:url] if params[:url].present?
    source
  end

  # GET /sources/1/edit
  def edit
    source
  end

  # POST /sources, # PUT /sources/1
  def create
    respond_to do |format|
      if source.update_attributes(params.permit![:source])
        format.html { redirect_to source, notice: 'Source was successfully saved.' }
        format.xml  { render xml: source, status: :created, location: source }
      else
        format.html { render action: source.new_record? ? "new" : "edit" }
        format.xml  { render xml: source.errors, status: :unprocessable_entity }
      end
    end
  end
  alias_method :update, :create

  # DELETE /sources/1
  def destroy
    ApplicationController::SharedDestroy.new(self).call(source)
  end
end

end
