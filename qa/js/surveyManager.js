/*CheckColumn Class from ExtJS*/
Ext.ns('Ext.ux.grid');
Ext.ux.grid.CheckColumn = function(config){
    Ext.apply(this, config);
    if(!this.id){
        this.id = Ext.id();
    }
    this.renderer = this.renderer.createDelegate(this);
};
Ext.ux.grid.CheckColumn.prototype ={
    init : function(grid){
        this.grid = grid;
        this.grid.on('render', function(){
            var view = this.grid.getView();
            view.mainBody.on('mousedown', this.onMouseDown, this);
            view.mainBody.on('mousedown', this.handler, this);
        }, this);
    },
    onMouseDown : function(e, t){
        if(t.className && t.className.indexOf('x-grid3-cc-'+this.id) != -1){
            e.stopEvent();
            var index = this.grid.getView().findRowIndex(t);
            var record = this.grid.store.getAt(index);
            record.set(this.dataIndex, !record.data[this.dataIndex]);
        }
    },
    renderer : function(v, p, record){
        p.css += ' x-grid3-check-col-td'; 
        return '<div class="x-grid3-check-col'+(v?'-on':'')+' x-grid3-cc-'+this.id+'">&#160;</div>';
    }
};
Ext.preg('checkcolumn', Ext.ux.grid.CheckColumn);
Ext.grid.CheckColumn = Ext.ux.grid.CheckColumn;

/*
 * Grid Drag 'n' Drop plugin created using code found in the ExtJS Forums
 */
Ext.namespace('Ext.ux.dd');

Ext.ux.dd.GridDragDropRowOrder = Ext.extend(Ext.util.Observable,
{
    copy: false,
    scrollable: false,
    constructor : function(config)
    {
        if (config)
            Ext.apply(this, config);

        this.addEvents(
        {
            beforerowmove: true,
            afterrowmove: true,
            beforerowcopy: true,
            afterrowcopy: true
        });

       Ext.ux.dd.GridDragDropRowOrder.superclass.constructor.call(this);
    },

    init : function (grid)
    {
        this.grid = grid;
        grid.enableDragDrop = true;

        grid.on({
            render: { fn: this.onGridRender, scope: this, single: true }
        });
    },

    onGridRender : function (grid)
    {
        var self = this;

        this.target = new Ext.dd.DropTarget(grid.getEl(),
        {
            ddGroup: grid.ddGroup || 'GridDD',
            grid: grid,
            gridDropTarget: this,

            notifyDrop: function(dd, e, data)
            {
                // Remove drag lines. The 'if' condition prevents null error when drop occurs without dragging out of the selection area
                if (this.currentRowEl)
                {
                    this.currentRowEl.removeClass('grid-row-insert-below');
                    this.currentRowEl.removeClass('grid-row-insert-above');
                }

                // determine the row
                var t = Ext.lib.Event.getTarget(e);
                var rindex = this.grid.getView().findRowIndex(t);
                if (rindex === false || rindex == data.rowIndex)
                {
                    return false;
                }
                // fire the before move/copy event
                if (this.gridDropTarget.fireEvent(self.copy ? 'beforerowcopy' : 'beforerowmove', this.gridDropTarget, data.rowIndex, rindex, data.selections, 123) === false)
                {
                    return false;
                }

                // update the store
                var ds = this.grid.getStore();

                // Changes for multiselction by Spirit
                var selections = new Array();
                var keys = ds.data.keys;
                for (var key in keys)
                {
                    for (var i = 0; i < data.selections.length; i++)
                    {
                        if (keys[key] == data.selections[i].id)
                        {
                            // Exit to prevent drop of selected records on itself.
                            if (rindex == key)
                            {
                                return false;
                            }
                            selections.push(data.selections[i]);
                        }
                    }
                }

                // fix rowindex based on before/after move
                if (rindex > data.rowIndex && this.rowPosition < 0)
                {
                    rindex--;
                }
                if (rindex < data.rowIndex && this.rowPosition > 0)
                {
                    rindex++;
                }

                // fix rowindex for multiselection
                if (rindex > data.rowIndex && data.selections.length > 1)
                {
                    rindex = rindex - (data.selections.length - 1);
                }

                // we tried to move this node before the next sibling, we stay in place
                if (rindex == data.rowIndex)
                {
                    return false;
                }

                // fire the before move/copy event
                /* dupe - does it belong here or above???
                if (this.gridDropTarget.fireEvent(self.copy ? 'beforerowcopy' : 'beforerowmove', this.gridDropTarget, data.rowIndex, rindex, data.selections, 123) === false)
                {
                    return false;
                }
                */

                if (!self.copy)
                {
                    for (var i = 0; i < data.selections.length; i++)
                    {
                        ds.remove(ds.getById(data.selections[i].id));
                    }
                }

                for (var i = selections.length - 1; i >= 0; i--)
                {
                    var insertIndex = rindex;
                    ds.insert(insertIndex, selections[i]);
                }

                // re-select the row(s)
                var sm = this.grid.getSelectionModel();
                if (sm)
                {
                    sm.selectRecords(data.selections);
                }

                // fire the after move/copy event
                this.gridDropTarget.fireEvent(self.copy ? 'afterrowcopy' : 'afterrowmove', this.gridDropTarget, data.rowIndex, rindex, data.selections);
                return true;
            },

            notifyOver: function(dd, e, data)
            {
                var t = Ext.lib.Event.getTarget(e);
                var rindex = this.grid.getView().findRowIndex(t);

                // Similar to the code in notifyDrop. Filters for selected rows and quits function if any one row matches the current selected row.
                var ds = this.grid.getStore();
                var keys = ds.data.keys;
                for (var key in keys)
                {
                    for (var i = 0; i < data.selections.length; i++)
                    {
                        if (keys[key] == data.selections[i].id)
                        {
                            if (rindex == key)
                            {
                                if (this.currentRowEl)
                                {
                                    this.currentRowEl.removeClass('grid-row-insert-below');
                                    this.currentRowEl.removeClass('grid-row-insert-above');
                                }
                                return this.dropNotAllowed;
                            }
                        }
                    }
                }

                // If on first row, remove upper line. Prevents negative index error as a result of rindex going negative.
                if (rindex < 0 || rindex === false)
                {
                    this.currentRowEl.removeClass('grid-row-insert-above');
                    return this.dropNotAllowed;
                }

                try
                {
                    var currentRow = this.grid.getView().getRow(rindex);
                    // Find position of row relative to page (adjusting for grid's scroll position)
                    var resolvedRow = new Ext.Element(currentRow).getY() - this.grid.getView().scroller.dom.scrollTop;
                    var rowHeight = currentRow.offsetHeight;

                    // Cursor relative to a row. -ve value implies cursor is above the row's middle and +ve value implues cursor is below the row's middle.
                    this.rowPosition = e.getPageY() - resolvedRow - (rowHeight/2);

                    // Clear drag line.
                    if (this.currentRowEl)
                    {
                        this.currentRowEl.removeClass('grid-row-insert-below');
                        this.currentRowEl.removeClass('grid-row-insert-above');
                    }

                    if (this.rowPosition > 0)
                    {
                        // If the pointer is on the bottom half of the row.
                        this.currentRowEl = new Ext.Element(currentRow);
                        this.currentRowEl.addClass('grid-row-insert-below');
                    }
                    else
                    {
                        // If the pointer is on the top half of the row.
                        if (rindex - 1 >= 0)
                        {
                            var previousRow = this.grid.getView().getRow(rindex - 1);
                            this.currentRowEl = new Ext.Element(previousRow);
                            this.currentRowEl.addClass('grid-row-insert-below');
                        }
                        else
                        {
                            // If the pointer is on the top half of the first row.
                            this.currentRowEl.addClass('grid-row-insert-above');
                        }
                    }
                }
                catch (err)
                {
                    console.warn(err);
                    rindex = false;
                }
                return (rindex === false)? this.dropNotAllowed : this.dropAllowed;
            },

            notifyOut: function(dd, e, data)
            {
                // Remove drag lines when pointer leaves the gridView.
                if (this.currentRowEl)
                {
                    this.currentRowEl.removeClass('grid-row-insert-above');
                    this.currentRowEl.removeClass('grid-row-insert-below');
                }
            }
        });

        if (this.targetCfg)
        {
            Ext.apply(this.target, this.targetCfg);
        }

        if (this.scrollable)
        {
            Ext.dd.ScrollManager.register(grid.getView().getEditorParent());
            grid.on({
                beforedestroy: this.onBeforeDestroy,
                scope: this,
                single: true
            });
        }
    },

    getTarget: function()
    {
        return this.target;
    },

    getGrid: function()
    {
        return this.grid;
    },

    getCopy: function()
    {
        return this.copy ? true : false;
    },

    setCopy: function(b)
    {
        this.copy = b ? true : false;
    },

    onBeforeDestroy : function (grid)
    {
        // if we previously registered with the scroll manager, unregister
        // it (if we don't it will lead to problems in IE)
        Ext.dd.ScrollManager.unregister(grid.getView().getEditorParent());
    }
});

/*	The JSON2XML function is licensed under Creative Commons GNU LGPL License.

	License: http://creativecommons.org/licenses/LGPL/2.1/
    Version: 0.9
	Author:  Stefan Goessner/2006
	Web:     http://goessner.net/ 
*/
function JSON2XML(o, tab) {
   var toXml = function(v, name, ind) {
      var xml = "";
      if (v instanceof Array) {
         for (var i=0, n=v.length; i<n; i++)
            xml += ind + toXml(v[i], name, ind+"\t") + "\n";
      }
      else if (typeof(v) == "object") {
         var hasChild = false;
         xml += ind + "<" + name;
         for (var m in v) {
            if (m.charAt(0) == "@")
               xml += " " + m.substr(1) + "=\"" + v[m].toString() + "\"";
            else
               hasChild = true;
         }
         xml += hasChild ? ">" : "/>";
         if (hasChild) {
            for (var m in v) {
               if (m == "#text")
                  xml += v[m];
               else if (m == "#cdata")
                  xml += "<![CDATA[" + v[m] + "]]>";
               else if (m.charAt(0) != "@")
                  xml += toXml(v[m], m, ind+"\t");
            }
            xml += (xml.charAt(xml.length-1)=="\n"?ind:"") + "</" + name + ">";
         }
      }
      else {
         xml += ind + "<" + name + ">" + v.toString() +  "</" + name + ">";
      }
      return xml;
   }, xml="";
   for (var m in o)
      xml += toXml(o[m], m, "");
   return tab ? xml.replace(/\t/g, tab) : xml.replace(/\t|\n/g, "");
}

//Primary Application
Ext.onReady(function(){

	//Fixes some Firebug issues
	Ext.override(Ext.Element, {
	    contains: function() {
	        var isXUL = Ext.isGecko ? function(node) {
	            return Object.prototype.toString.call(node) == '[object XULElement]';
	        } : Ext.emptyFn;
	
	        return function(el) {
	            return !this.dom.firstChild || // if this Element has no children, return false immediately
	                   !el ||
	                   isXUL(el) ? false : Ext.lib.Dom.isAncestor(this.dom, el.dom ? el.dom : el);
	        };
	    }
	});

	Ext.QuickTips.init();
	
	Ext.getBody().on('contextmenu', function(e){
		//Ignore right clicking. Contextmenu listeners will override this.
		e.preventDefault();
	});
	
	//Config Elements
	cfg = {};
	cfg.ajax = "ajax.cfm";
	cfg.report = "report.cfm";
	cfg.map = "map.cfm";
	
	//DATA STORES
	var storeAnswerType = new Ext.data.SimpleStore({
		fields: ['val','nm'],
		data: [['text_single','Text: One Line'],['text_multi','Text: Multi-line'],['boolean_tf','True/False'],['boolean_yn','Yes/No'],['rate_','Rate'],['date_','Date'],['select_single','Multiple Choice: Single Answer'],['select_multi','Multiple Choice: Multi-Answer'],['matrix_single','Matrix: Single Answer'],['matrix_multi','Matrix: Multi-Answer'],['hidden_','Hidden']]
	});
	
	var sr = Ext.data.Record.create([
		{name:'display',mapping:'display'},
		{name:'format',mapping:'format'},
		{name:'value',mapping:'value'}
	]);
	
	var storeProperty = new Ext.data.SimpleStore({
		fields: ['property','value'],
		data: []
	});
	
	var propertyr = Ext.data.Record.create([
		{name:'property',mapping:'property'},
		{name:'value',mapping:'value'}
	]);

	
	var storeACL = new Ext.data.SimpleStore({
		fields: ['display'],
		data: []
	});
	
	var aclr = Ext.data.Record.create([
		{name:'display',mapping:'display'}
	]);
	
	var currSurvey = "";
	
	//UTILITIES	
	var tools = [{
       id:'close',
       handler: function(e, target, panel){
          Ext.MessageBox.confirm('Remove Question','Are you sure you want to remove <b>'+panel.title+'</b>',function(btn){
           		if (btn == "yes")
           			panel.ownerCt.remove(panel, true);
           			changeQuestions();
          });
       }
   	}];
   	
   	var typeMenu = new Ext.menu.Menu({
		id: 'typeMenu',
		items: []
	});
	for (var i=0;i<storeAnswerType.getCount();i++) {
		var d = storeAnswerType.getAt(i).data;
		typeMenu.add({
			id: d.val,
			text: d.nm,
			handler: function() {addQuestion(this.id);},
			iconCls:'icon-bullet-menu'
		});
	}
	
	//UI OBJECTS
	var ctg = new Ext.tree.TreePanel({
		title: 'Surveys',
		region: 'west',
		layout: 'fit',
		width: 300,
		useArrows: true,
		enableDD: true,
		autoScroll: true,
		closable: false,
		collapsible: false,
		rootVisible: true,
		tbar: new Ext.Toolbar({
			items: [{
				text: 'New',
				iconCls:'icon-script-add',
				handler: createSurvey
			},{
				text:'Copy',
				iconCls:'icon-copy',
				disabled: true,
				handler: copySurvey
			},{
				text:'Delete',
				iconCls:'icon-remove',
				disabled: true,
				handler: deleteSurvey
			},'-',{
				text:'Add Folder',
				iconCls:'icon-folder-add',
				disabled: true,
				handler: addDirectory
			}]
		}),
		root: new Ext.tree.TreeNode({
			text: 'All Surveys',
			iconCls:'icon-root',
			allowDrag:false,
			expanded: true,
			listeners: {
				click: function(t,e) {
					ctg.getTopToolbar().items.get(1).disable();
					ctg.getTopToolbar().items.get(2).disable();
					ctg.getTopToolbar().items.get(4).enable();
				}
			}
		}),
		listeners: {
			beforerender: function (tree) {
				var msk = new Ext.LoadMask(Ext.getBody(),{msg:'Loading Surveys... Please Wait.'});
				msk.show();
				Ext.Ajax.request({
					url: cfg.ajax,
					params: {get:'surveys'},
					success: function(response,opts) {
						var obj = Ext.decode(response.responseText).surveys;
						for (var i=0; i<obj.length;i++) {
							if (obj[i].dir != undefined) {
								var nd = new Ext.tree.TreeNode({
									text: obj[i].dir,
									allowDrag: true,
									allowDrop: true,
									id:obj[i].dir,
									listeners: {
										click: function(t,e) {
											tree.getTopToolbar().items.get(1).disable();
											tree.getTopToolbar().items.get(2).enable();
											tree.getTopToolbar().items.get(4).enable();
										}
									}
								});
								//Add subdirectories
								for (var x=0; x<obj[i].sub.length; x++)
									nd.appendChild(createSubDirectory(obj[i].sub[x]));
								//Add files
								for(var y=0; y<obj[i].files.length; y++) {
									nd.appendChild(new Ext.tree.TreeNode({
										text:obj[i].files[y].nm,
										id:obj[i].files[y].nm,
										leaf:true,
										qtip:obj[i].files[y].sz+' bytes',
										iconCls:'icon-script',
										data: obj[i].files[y],
										listeners: {
											dblclick: function(node,e) {
												openSurvey(node.attributes.data.pth,node.text);
											},
											click: function(t,e) {
												tree.getTopToolbar().items.get(1).enable();
												tree.getTopToolbar().items.get(2).enable();
												tree.getTopToolbar().items.get(4).disable();
											},
											contextmenu: function(node,e) {
												node.select();
												var ctx = new Ext.menu.Menu({
													items:[{
														text:'Edit',
														iconCls:'icon-script',
														handler: function() {openSurvey(node.attributes.data.pth,node.text);}
													},{
														text:'Copy',
														iconCls:'icon-copy',
														handler: copySurvey
													},{
														text:'Delete',
														iconCls:'icon-remove',
														handler: deleteSurvey
													}]
												});
												ctx.showAt(e.getXY());
											}
										}
									}));
								}
								tree.root.appendChild(nd);
							} else {
								//Add root files
								tree.root.appendChild(new Ext.tree.TreeNode({
									text:obj[i].nm,
									id:obj[i].nm,
									leaf:true,
									qtip:obj[i].sz+' bytes',
									iconCls:'icon-script',
									data: obj[i],
									listeners: {
										dblclick: function(node,e) {
											openSurvey(node.attributes.data.pth,node.text);
										},
										click: function(t,e) {
											tree.getTopToolbar().items.get(1).enable();
											tree.getTopToolbar().items.get(2).enable();
											tree.getTopToolbar().items.get(4).disable();
										},
										contextmenu: function(node,e) {
											node.select();
											var ctx = new Ext.menu.Menu({
												items:[{
													text:'Edit Survey',
													iconCls:'icon-script',
													handler: function() {openSurvey(node.attributes.data.pth,node.text);}
												},{
													text:'Copy',
													iconCls:'icon-copy',
													handler: copySurvey
												},{
													text:'Delete',
													iconCls:'icon-remove',
													handler: deleteSurvey
												}]
											});
											ctx.showAt(e.getXY());
										}
									}
								}));
							}
						}
						msk.hide();
					}
				});
			},
			beforemovenode: function(tree,node,oldParent,newParent,i) {
				if (oldParent!=newParent) {
					var pth = "";
					var op ="";
					var np = "";
					var file = [];
					oldParent.bubble(function(){
						if (this != ctg.root)
							op = "/"+this.text+op;
					});
					newParent.bubble(function(){
						if (this != ctg.root)
							np = "/"+this.text+np;
					});
					if (node.isLeaf()) {
						pth = node.attributes.data.pth;
						file = pth.split("/");
						node.attributes.data.pth = np+"/"+file[file.length-1];
					} else {
						node.bubble(function(){
							if (this != ctg.root)
								pth = "/"+this.text+pth;
						});
					}
					Ext.Ajax.request({
						url:cfg.ajax,
						params:{
							get:node.isLeaf()==true?'movesurvey':'movefolder',
							path:pth,
							oldparent:op,
							newparent:np
						},
						failure: function() {
							return false;
						}
					});
				}
			}
		}
	});
	
	var processing = new Ext.Panel({
		iconCls:'icon-gear',
		title: 'Processing',
		layout:'fit',
		border:false,
		bodyStyle: 'padding:20px',
		items: [new Ext.form.FormPanel({
			border:false,
			defaults:{
				xtype:'textfield',
				width:400,
				border:false,
				enableKeyEvents:true,
				listeners: {
					keyup: function(){changeQuestions();}
				}
			},
			items:[{
				fieldLabel:'Form URL',
				allowBlank:false,
				emptyText:'http://mydomain.com/surveyPage.cfm'
			},{
				fieldLabel:'Processing URL',
				allowBlank:false,
				emptyText:'http://mydomain.com/actionPage.cfm'
			},{
				xtype:'textarea',
				fieldLabel:'Notify',
				height:125
			},{
				fieldLabel: ' ',
				labelSeparator:' ',
				xtype:'panel',
				html:'<font style="font-size:x-small;">This is usually a delimited list of email addresses. The values are available when the form is generated. Common use includes sending the results to specific email addresses.</font><br/><br/>'
			},{
				xtype:'datefield',
				fieldLabel:'Active From'
			},{
				xtype:'datefield',
				fieldLabel:'Expiration'
			}]
		})],
		tbar: new Ext.Toolbar({
			items: [{
				text: 'Save',
				iconCls:'icon-save',
				handler: saveForm,
				disabled: true
			}]
		})
	}); 
	
	var acl = new Ext.Panel({
		iconCls:'icon-users',
		title: 'Security',
		layout:'fit',
		border:false,
		bodyStyle: 'padding:20px',
		items: [new Ext.form.FormPanel({
			border:false,
			defaults:{
				xtype:'textfield',
				width:500,
				border:false
			},
			items:[{
				xtype:'checkbox',
				fieldLabel:'Private',
				checked: false,
				listeners: {
					check: function(cb,checked) {
						if (checked) {
							acl.items.get(0).items.get(1).enable();
							acl.items.get(0).items.get(2).enable();
						} else {
							acl.items.get(0).items.get(1).disable();
							acl.items.get(0).items.get(2).disable();
						}
						changeQuestions();
					}
				}
			},{
				fieldLabel:'Password',
				disabled: true,
				enableKeyEvents: true,
				listeners: {
					keyup: function() {changeQuestions();}
				}
			},new Ext.grid.EditorGridPanel({
				fieldLabel: 'Authorized',
				border: true,
				frame: true,
				disabled: true,
				title: 'Access Control List',
				height: 200,
				cm: new Ext.grid.ColumnModel({
					defaults:{sortable:true},
					columns: [
						{
							header:'Email/Login/User/Identifier',
							sortable: true,
							dataIndex:'display',
							editor:new Ext.form.TextField({
								allowBlank:false
							})
						}
					]
				}),
				sm: new Ext.grid.RowSelectionModel({singleSelect:true}),
				clicksToEdit: 1,
				viewConfig: {forceFit:true},
				iconCls:'icon-users',
				store: storeACL,
				tbar: [{
					iconCls:'icon-add',
		            text: 'Add',
		            handler : function(){
		                // access the Record constructor through the grid's store
		                var grid = this.ownerCt.ownerCt;
		                var p = new aclr({
		                    display: 'New Authorized User'
		                });
		                grid.stopEditing();
		                storeACL.insert(0,p);
		                grid.startEditing(0,0);
		                changeQuestions();
		            }
		        },{
		        	iconCls:'icon-remove',
		        	text:'Remove',
		        	handler: function() {
		        		var grid = this.ownerCt.ownerCt;
		        		storeACL.remove(grid.getSelectionModel().getSelected());
		                changeQuestions();
		        	}
		        },'-',{
		        	iconCls:'icon-clear',
		        	text:'Clear All',
		        	handler: function() {
		        		storeACL.removeAll();
		                changeQuestions();
		        	}
		        }]
			})]
		})],
		tbar: new Ext.Toolbar({
			items: [{
				text: 'Save',
				iconCls:'icon-save',
				handler: saveForm,
				disabled: true
			}]
		})
	}); 

	var r1 = new Ext.Panel({
		title: 'Summary',
		html:''
	});
	var r2 = new Ext.Panel({
		title: 'Distribution',
		html:''
	});
	var r3 = new Ext.Panel({
		title: 'Coverage',
		html:''
	});
	
	var results = new Ext.TabPanel({
		title: 'Results',
		activeTab: 0,
		items: []
	});
	
	var editor = new Ext.Panel({
		region:'center',
		layout: 'fit',
		title:'&laquo; Select a Survey From the Left',
		items: [new Ext.TabPanel({
			disabled: true,
			border: false,
			activeTab: 0,
			items: [new Ext.Panel({
				iconCls:'icon-help',
				title: 'Questions',
				layout: 'fit',
				tbar: new Ext.Toolbar({
					items: [{
						text: 'Save',
						iconCls:'icon-save',
						disabled: 'true',
						handler: saveForm
					},'-',{
						text:'Add Question',
						iconCls:'icon-add',
						menu: typeMenu
					},{
						text:'Expand All',
						enableToggle: true,
						iconCls:'icon-expand',
						handler: function(btn) {
							var qa = editor.items.get(0).items.get(0).items.get(0).items.get(0);
							var q = qa.items;
							for (i=0;i<q.length;i++) {
								if (btn.pressed)
									q.get(i).expand(false);
								else
									q.get(i).collapse(false);
							}
							qa.doLayout();
						}
					},'->','Drag Questions to Reorder.']
				}),
				items:[{
					xtype:'portal',
					border: false,
					bodyStyle:'padding: 20px;',
					layout: 'fit',
					items: [{
						columnWidth: 1,
						defaults: {bodyStyle:'padding: 7px;padding-top:15px;padding-bottom:15px;'},
						items: []
					}],
					listeners: {
						drop: changeQuestions
					}
				}]
			})
			,processing
			,acl
			,results]
		})]
	});
	
	var properties = new Ext.Panel({
		disabled: true,
		region: 'east',
		collapsible: true,
		collapsed: true,
		width: 275,
		iconCls:'icon-properties',
		title:'Properties',
		layout:'fit',
		items: [new Ext.grid.GridPanel({
			border: false,
			disabled: true,
			header: false,
			cm: new Ext.grid.ColumnModel({
				defaults:{sortable:true},
				columns: [
					{
						header:'Property',
						sortable: true,
						dataIndex:'property',
						width:40
					},{
						header:'Value',
						sortable: false,
						dataIndex:'value'
					}
				]
			}),
			sm: new Ext.grid.RowSelectionModel({singleSelect:true}),
			clicksToEdit: 1,
			viewConfig: {forceFit:true},
			store: storeProperty,
			tbar: new Ext.Toolbar({
				items: [{
					text:'Edit',
					iconCls:'icon-edit',
					handler: editProperties
				}]
			})
		})]
	});
	
	//This section cannot be edited without breaking the terms of the license,
	//nor can this element or its parent elements be removed from the application.
	//In other words, the credit must show up somewhere in plain view in order to
	//use this for free.
	//---------- BEGIN CREDIT --------------
	var foot = new Ext.Toolbar({
		height: 25,
		region:'south',
		items: [{xtype:'tbfill'},{
			disabled: true,
			text:'For non-commercial use only.'
		},{
			xtype:'spacer',
			width:15
		},{
			text: "Built by Ecor Systems",
			handler: function() {
				document.location="http://www.ecorsystems.com"
			}
		},{
			xtype:'spacer',
			width:15
		}]
	});
	//---------- END CREDIT --------------

	var loginWin = new Ext.Window({
		title: 'Authorization Required',
		border: false,
		height: 140,
		width: 380,
		closable: false,
		resizable: false,
		modal: true,
		items: [new Ext.form.FormPanel({
			bodyStyle: 'padding: 15px;',
			defaults: {xtype:'textfield'},
			items: [{
				fieldLabel: 'Username',
				width: 200,
				allowBlank:false,
				emptyText:'Your username...',
				enableKeyEvents: true,
				listeners: {
					keyup: function(tf,e) {
						var sbtn = loginWin.items.get(0).getBottomToolbar().items.get(1);
						if (tf.getRawValue().length == 0)
							sbtn.disable();
						else if (loginWin.items.get(0).items.get(1).getRawValue().length==0)
							sbtn.disable();
						else
							sbtn.enable();
					}
				}
			},{
				fieldLabel: 'Password',
				width: 200,
				inputType: 'password',
				enableKeyEvents: true,
				allowBlank:false,
				listeners: {
					keyup: function(tf,e) {
						var sbtn = loginWin.items.get(0).getBottomToolbar().items.get(1);
						if (tf.getRawValue().length == 0)
							sbtn.disable();
						else if (loginWin.items.get(0).items.get(0).getRawValue().length==0)
							sbtn.disable();
						else
							sbtn.enable();
					}
				}
			}],
			bbar: new Ext.Toolbar({
				items: [{xtype:'tbfill'},{
					text: 'Login',
					iconCls: 'icon-login',
					disabled: true,
					handler: function() {
						var usr = loginWin.items.get(0).items.get(0).getRawValue();
						var pwd = loginWin.items.get(0).items.get(1).getRawValue();
						Ext.Ajax.request({
							url:cfg.ajax,
							params: {get:'auth',j_username:usr,j_password:pwd},
							success: function(r,o) {
								if (Ext.decode(r.responseText).auth)
									loginWin.destroy();
								else {
									loginWin.setIconClass('icon-invalid');
									loginWin.setTitle("Authorization Failed: Try Again.");
									loginWin.items.get(0).getBottomToolbar().items.get(1).disable();
									loginWin.items.get(0).items.get(1).reset();
								}
							}
						});
					}
				}]
			})
		})]
	});
	
	//MAIN LAYOUT
	new Ext.Viewport({
		layout: 'border',
		border: false,
		defaults: {split: true},
		items: [ctg,editor,properties,foot],
		listeners: {
			render: function(vp) {
				Ext.Ajax.request({
					url:cfg.ajax,
					params: {get:'forceauth'},
					success: function(r,o) {
						var on = (Ext.decode(r.responseText).auth==true);
						if (on)
							loginWin.show();
					}
				})
			}
		}
	});	
	
	//FUNCTIONALITY
	function openSurvey(path,name) {
		var msk = new Ext.LoadMask(editor.getEl(),{msg:'Loading '+name+'...'});
		msk.show();
		Ext.Ajax.request({
			url:cfg.ajax,
			params: {get:'survey',path:path},
			success: function(response,opt) {
				var obj = Ext.decode(response.responseText);
				var qa = obj.questions;
				var acl = obj.acl;
				var qaTab = editor.items.get(0).items.get(0).items.get(0).items.get(0);
				var pTab = editor.items.get(0).items.get(1).items.get(0);
				var sTab = editor.items.get(0).items.get(2).items.get(0);
				
				//Set current survey
				currSurvey = path;
				editor.setTitle('Now Editing: '+name);
				
				//Update Properties
				storeProperty.removeAll();
				storeProperty.add(new propertyr({
        			property:'Title',
        			value:obj.title
        		}));
				storeProperty.add(new propertyr({
        			property:'Description',
        			value:obj.description
        		}));
        		var fp = path.split("/");
				storeProperty.add(new propertyr({
        			property:'File',
        			value:fp[fp.length-1]
        		}));
				/*storeProperty.add(new propertyr({
        			property:'ID',
        			value:obj.ID
        		}));*/
				storeProperty.add(new propertyr({
        			property:'Last Modified',
        			value:obj.moddate
        		}));
        		properties.items.get(0).enable();
				
				//Update processing info
				pTab.items.get(0).setValue(obj.url);
				pTab.items.get(1).setValue(obj.action);
				pTab.items.get(2).setValue(obj.alert);
				pTab.items.get(4).setValue(obj.start);
				pTab.items.get(5).setValue(obj.end);
				
				//Update security detail
				sTab.items.get(0).setValue(obj.private);
				sTab.items.get(1).setValue(obj.password);
				storeACL.removeAll();
				for(i=0;i<acl.length;i++)
					storeACL.add(new aclr({display:acl[i]}));
				if (obj.private) {
					sTab.items.get(1).enable();
					sTab.items.get(2).enable();
				}
				
				//Add questions
				qaTab.removeAll();
				for (i=0; i<qa.length; i++)
					qaTab.add(question(qa[i]));
				qaTab.doLayout();
				qaTab.syncSize();
				editor.items.get(0).enable();
				properties.enable();
				
				//Load results pages
				results.removeAll();

				var tmp = new Ext.Panel({
					title:'Summary',
					autoLoad: {url:cfg.report+"?survey="+currSurvey},
					autoScroll: true,
					tbar: new Ext.Toolbar({
						items: [{
							text: 'See Map',
							handler: openMap
						}]
					})
				});
				results.add(tmp);
				var tmp = new Ext.Panel({
					title:'Detail',
					autoLoad: {url:cfg.report+"?detail&survey="+currSurvey},
					autoScroll: true
				});
				results.add(tmp);
				results.doLayout();
								
				//Unhide
				msk.hide();
			}
		});
	}
	
	
	function question(q) {
		var fmt = "";
		if (q.format==undefined)
			fmt = q.type+'_';
		else
			fmt = q.type+'_'+q.format;
		
		var qp = new Ext.Panel({
			title: q.text!=undefined?q.text:q.name,
			draggable: true,
			titleCollapse: true,
			collapsible: true,
			collapsed: true,
			closable: true,
			forceLayout:true,
			tools: tools,
			data: q,
			tbar: new Ext.Toolbar({
				items: [{
					text:q.text==undefined?'Fieldname: ':'Edit: ',
					disabled: true
				},{
					xtype:'textfield',
					width: 300,
					value:q.text!=undefined?q.text:q.name,
					emptyText:q.text!=undefined?'Type your question here...':'Fieldname...',
					allowBlank:false,
					hideLabel: false,
					fieldLabel:'Edit Question',
					enableKeyEvents: true,
					listeners: {
						keyup: function(field,e) {
							var p = field.ownerCt.ownerCt;
							var mp = p.ownerCt;
							var qtab = editor.items.get(0).items.get(0);
							p.setTitle(field.getRawValue());
							if (p.data.type=="hidden")
								p.data.name=field.getRawValue();
							changeQuestions();								
						}
					}
				},'',{
					text:'Required',
					disabled: true
				},new Ext.form.Checkbox({
					checked: q.text==undefined?true:q.required,
					disabled: q.text==undefined?true:false,
					listeners: {
						check: function(cb,checked) {
							if (checked)
								qp.setIconClass('icon-help-required');
							else
								qp.setIconClass('icon-help');
							changeQuestions();
						}
					}
				}),'','-','',"Type: "+storeAnswerType.getAt(storeAnswerType.find('val',fmt)).data.nm,'->',{
					text: 'Edit Options',
					iconCls:'icon-edit',
					hidden: q.type=="select"||q.type=="matrix"||q.type=="rate" ? false:true,
					handler: function(t) {
						editOptions(q,t.ownerCt.ownerCt);
					}
				}]
			}),
			items:[new Ext.form.FormPanel({
				border: false,
				header: false,
				items: [{
					border:false,
					html:"<i>Example:</i><br/><br/>"
				}]
			})],
			listeners: {
				close: function(p) {
					changeQuestions();
				},
				render: function(t) {
					if (q.text==undefined)
						this.setIconClass('icon-help-hidden');
					else if (q.required)
						this.setIconClass('icon-help-required');
					else
						this.setIconClass('icon-help');
				}
			}
		});
		
		if (q.type=="hidden") {
			qp.getTopToolbar().add({
				text:'Value',
				disabled: true
			});
			qp.getTopToolbar().add({
				xtype:'textfield',
				value:q.value,
				width: 200,
				enableKeyEvents:true,
				listeners: {
					keyup:function(tf){
						qp.data.value=tf.getRawValue();
						changeQuestions();
					}
				}
			});
		}
		
		//Add to object
		qp.add(questionContents(q));
		qp.doLayout();
		return qp;
	}
	
	function questionContents(q) {
		/*
		var qtype = new Ext.form.ComboBox({
			editable: false,
			hideLabel:true,
		    store: storeAnswerType,
		    displayField:'nm',
		    valueField:'val',
		    typeAhead: false,
		    mode: 'local',
		    triggerAction: 'all',
		    emptyText:'Select a question type...',
		    width: 200,
		    minListWidth: 200,
		    selectOnFocus:true,
		    allowBlank: false,
		    forceSelection: true,
		    listeners: {
		    	select: function(field,record,i) {
		    		var val = record.data.val.split("_");
		    		var tb = field.ownerCt.ownerCt.getTopToolbar(); 
		    		if (val[0]=="select")
		    			tb.items.get(tb.items.length-1).show();
		    		else
		    			tb.items.get(tb.items.length-1).hide();
		    		changeQuestions();
		    	}
		    }
		});
		qtype.setValue(fmt);
		*/
		var fmt = "";
		if (q.format==undefined)
			fmt = q.type+'_';
		else
			fmt = q.type+'_'+q.format;
			
		var f = new Ext.form.FormPanel({
			id:'demo_'+q.id,
			border: false,
			header: false,
			items: [{
				xtype:'panel',
				border: false,
				header: false,
				html: "<b>"+q.text+"</b>"
			},{
				border: false,
				height: 10
			}]
		});
		
		switch (fmt) {
			case "date_":
				f.add({
					hideLabel:true,
					height: 20,
					width: 300
				});
				break;
			case "text_single":
				f.add({
					hideLabel:true,
					blankText:'User answer goes here.',
					height: 20,
					width: 300
				});
				break;
			case "text_multi":
				f.add({
					xtype:'textarea',
					hideLabel:true,
					blankText:'User answer goes here.',
					height: 60,
					width: 300
				});
				break;
			case "boolean_tf":
				f.add({
					xtype:'radiogroup',
					hideLabel: true,
					columns: 1,
					items: [{
						name:'demor'+q.id,
						boxLabel:'True',
						checked: true,
						inputValue: true
					},{
						name:'demor'+q.id,
						boxLabel:'False',
						checked: false,
						inputValue: false
					}]
				});
				break;
			case "boolean_yn":
				f.add({
					xtype:'radiogroup',
					hideLabel: true,
					columns: 1,
					items: [{
						name:'demor'+q.id,
						boxLabel:'Yes',
						checked: true,
						inputValue: true,
						width: 35
					},{
						name:'demor'+q.id,
						boxLabel:'No',
						checked: false,
						inputValue: false,
						width: 35
					}]
				});
				break;
			case "rate_":
				var tmp = new Array();
				var n = q.from;
				for (n=q.from; n<=q.to; n=n+q.increment) {
					tmp.push({
						name:'demor'+q.id,
						boxLabel:n,
						checked: n==q.from?true:false,
						inputValue: n
					});
				}
				f.add({
					xtype:'radiogroup',
					hideLabel: true,
					items: tmp
				});
				break;
			case "select_single":
				var opts = [];
				for (x=0; x<q.answer.length; x++) {
					var ans = q.answer[x];
					if (ans!=undefined) {
						opts.push({
							name:'demor'+q.id,
							boxLabel:ans.display,
							checked: x==0?true:false,
							inputValue: ans.value!=undefined?ans.value:ans.display
						});
						if (ans.format == "text") {
							opts.push({
								xtype:"panel",
								width: 300,
								border:false,
								items:[{
									xtype:'textfield',
									width:300
								}]
							});
						}
					}
				}
				if (opts.length) {
					f.add({
						xtype:'radiogroup',
						hideLabel: true,
						columns: 1,
						items: opts
					});
				}
				break;
			case "select_multi":
				var opts = [];
				for (x=0; x<q.answer.length; x++) {
					var ans = q.answer[x];
					if (ans!=undefined) {
						opts.push({
							name:'demor'+q.id,
							boxLabel:ans.display,
							checked: x==0?true:false,
							inputValue: ans.value!=undefined?ans.value:ans.display
						});
						if (ans.format == "text") {
							opts.push({
								xtype:"panel",
								width: 300,
								border:false,
								items:[{
									xtype:'textfield',
									width:300
								}]
							});
						}
					}
				}
				if (opts.length) {
					f.add({
						xtype:'checkboxgroup',
						hideLabel: true,
						columns: 1,
						items: opts
					});
				}
				break;
			case "matrix_single":
				if (!(q.answer.columns.length == q.answer.options.length && q.answer.columns.length==0)) {
					var table = new Ext.Panel({
						border: false,
						layout:'table',
						defaults: {border:false,height:25,bodyStyle:'padding:8px'},
						layoutConfig: {columns:q.answer.columns.length+1}
					});
					
					table.add({html:""});
					for (n=0;n<q.answer.columns.length;n++) {
						table.add({
							html:q.answer.columns[n]
						});
					}
					for (n=0;n<q.answer.options.length;n++) {
						table.add({html:"<i>"+q.answer.options[n].display+"</i>"});
						//var rg = {xtype:'radiogroup'}
						for (y=0;y<q.answer.columns.length;y++) {
							table.add(new Ext.form.Radio({
								name: 'opt_'+q.answer.columns[y],
								inputValue:q.answer.options[n].value
							}));
						}
					}
					f.add(table);
				}
				break;
			case "matrix_multi":
				if (!(q.answer.columns.length == q.answer.options.length && q.answer.columns.length==0)) {
					var table = new Ext.Panel({
						border: false,
						layout:'table',
						defaults: {border:false,height:25,bodyStyle:'padding:8px'},
						layoutConfig: {columns:q.answer.columns.length+1}
					});
					
					table.add({html:""});
					for (n=0;n<q.answer.columns.length;n++) {
						table.add({
							html:q.answer.columns[n]
						});
					}
					for (n=0;n<q.answer.options.length;n++) {
						table.add({html:"<i>"+q.answer.options[n].display+"</i>"});
						//var rg = {xtype:'radiogroup'}
						for (y=0;y<q.answer.columns.length;y++) {
							table.add(new Ext.form.Checkbox({
								name: 'opt_'+q.answer.columns[y],
								inputValue:q.answer.options[n].value
							}));
						}
					}
					f.add(table);
				}
				break;
		}
		if (q.type != "hidden") {
			f.doLayout();
			return f;
		} else
			return {border:false,html:'<b>No example available (hidden field)</b>'};
	}
	
	
	function addQuestion(type) {
		var t = type.split("_")[0];
		var fmt = type.split("_")[1];
		var qtab = editor.items.get(0).items.get(0).items.get(0).items.get(0);
		
		//Create a question object
		if (t=="hidden") {
			var q = {
				id: 'newQ',
				type: t,
				value: '',
				name: 'unknown'+qtab.items.length
			}
		} else {
			var q = {
				id: 'newQ',
				text: 'Question #'+qtab.items.length,
				type: t,
				required: false,
				format: fmt==undefined||fmt.length==0?'':fmt
				//default: t=="boolean"?true:null
			};
			switch (t) {
				case "select":
					q.answer = [];
					break;
				case "matrix":
					q.answer = {};
					q.answer.columns = [];
					q.answer.options = [];
					break;
				case "rate":
					q.from=1;
					q.to=5;
					q.increment=1;
					break;
			}
		}
		//Add question to screen
		qtab.add(question(q));
		qtab.doLayout();
		qtab.items.get(qtab.items.length-1).expand();
		changeQuestions();
	}
	
	function editProperties() {
		var grid = properties.items.get(0);
		
		var propWin = new Ext.Window({
			title:'Edit Properties',
			width: 450,
			height: 300,
			layout:'fit',
			iconCls:'icon-edit',
			modal:true,
			items: [new Ext.form.FormPanel({
				bodyStyle:'padding:15px',
				border: false,
				defaults:{xtype:'textfield',width:300,enableKeyEvents:true},
				items: [{
					fieldLabel:'Name',
					value: storeProperty.getAt(0).data.value,
					listeners: {
						keyup: function(tf,e) {
							editor.setTitle("*Now Editing: "+tf.getValue());
							storeProperty.getAt(0).set('value',tf.getValue());
							changeQuestions();
						}
					}
				},{
					fieldLabel:'Decription',
					xtype:'textarea',
					value: storeProperty.getAt(1).data.value,
					height: 175,
					listeners: {
						keyup: function(tf,e) {
							storeProperty.getAt(1).set('value',tf.getValue());
							changeQuestions();
						}
					}
				}]
			})],
			bbar: new Ext.Toolbar({
				items:['->','Close this window when you\'re done editing, then save.']	
			})
		});
		propWin.show();
	}
	
	function editOptions(q,p) {
		switch(q.type) {
			case "matrix":
				var ss = new Ext.data.SimpleStore({
					fields: ['display'],
					data: []
				});
				var ss2 = new Ext.data.SimpleStore({
					fields: ['display','value'],
					data: []
				});
				var sr2 = Ext.data.Record.create([
					{name:'display',mapping:'display'}
				]);
				var sr3 = Ext.data.Record.create([
					{name:'display',mapping:'display'},
					{name:'display',mapping:'value'}
				]);
				for(i=0;i<q.answer.columns.length;i++)
					ss.add(new sr2({display:q.answer.columns[i]}));
				for(i=0;i<q.answer.options.length;i++)
					ss2.add(new sr2({display:q.answer.options[i].display,value:q.answer.options[i].value}));
				var cm = new Ext.grid.ColumnModel({
					defaults:{sortable:true},
					columns: [
						{
							header:'Column Header',
							width:200,sortable: true,
							dataIndex:'display',
							editor:new Ext.form.TextField({
								allowBlank:false,
								listeners: {
									change: function() {
										qWin.getBottomToolbar().items.get(2).enable();
									}
								}
							})
						}
					]
				});
				var cm2 = new Ext.grid.ColumnModel({
					defaults:{
						sortable:true,
						width:200,
						editor:new Ext.form.TextField({
							allowBlank:false,
							listeners: {
								change: function() {
									qWin.getBottomToolbar().items.get(2).enable();
								}
							}
						})
					},
					columns: [
						{
							header:'Row Header',
							dataIndex:'display'
						},{
							header:'Row Value',
							dataIndex:'value'
						}
					]
				});
				var qWin = new Ext.Window({
					title: "Options for: "+p.title,
					width: 500,
					height: 300,
					layout:'fit',
					border: false,
					iconCls:'icon-edit',
					modal: true,
					items: [{
						layout:'border',
						items: [new Ext.grid.EditorGridPanel({
							region:'center',
							border: false,
							width: 250,
							cm:cm,
							sm: new Ext.grid.RowSelectionModel({singleSelect:true}),
							enableDragDrop: true,
							clicksToEdit: 1,
							viewConfig: {forceFit:true},
							iconCls:'icon-edit',
							store: ss,
							plugins: [new Ext.ux.dd.GridDragDropRowOrder({
						        scrollable: true
						    })],
							tbar: [{
								iconCls:'icon-add',
					            text: 'Add',
					            handler : function(){
					                // access the Record constructor through the grid's store
					                var grid = qWin.items.get(0).items.get(0);
					                var p = new sr2({
					                    display: 'New Column'
					                });
					                grid.stopEditing();
					                ss.insert(0, p);
					                grid.startEditing(0,0);
					                qWin.getBottomToolbar().items.get(2).enable();
					            }
					        },{
					        	iconCls:'icon-remove',
					        	text:'Remove',
					        	handler: function() {
					        		var grid = qWin.items.get(0).items.get(0);
					        		ss.remove(grid.getSelectionModel().getSelected());
					                qWin.getBottomToolbar().items.get(2).enable();
					        	}
					        },'-',{
					        	iconCls:'icon-clear',
					        	text:'Clear Columns',
					        	handler: function() {
					        		ss.removeAll();
					                qWin.getBottomToolbar().items.get(2).enable();
					        	}
					        }]
						}),new Ext.grid.EditorGridPanel({
							region:'east',
							border: false,
							width: 240,
							cm:cm2,
							sm: new Ext.grid.RowSelectionModel({singleSelect:true}),
							enableDragDrop: true,
							clicksToEdit: 1,
							viewConfig: {forceFit:true},
							iconCls:'icon-edit',
							store: ss2,
							plugins: [new Ext.ux.dd.GridDragDropRowOrder({
						        scrollable: true
						    })],
							tbar: [{
								iconCls:'icon-add-row',
					            text: 'Add',
					            handler : function(){
					                // access the Record constructor through the grid's store
					                var grid = qWin.items.get(0).items.get(1);
					                var p = new sr3({
					                    display: 'New Row',
					                    value: ''
					                });
					                grid.stopEditing();
					                ss2.insert(0, p);
					                grid.startEditing(0,0);
					                qWin.getBottomToolbar().items.get(2).enable();
					            }
					        },{
					        	iconCls:'icon-remove-row',
					        	text:'Remove',
					        	handler: function() {
					        		var grid = qWin.items.get(0).items.get(1);
					        		ss2.remove(grid.getSelectionModel().getSelected());
					                qWin.getBottomToolbar().items.get(2).enable();
					        	}
					        },'-',{
					        	iconCls:'icon-clear',
					        	text:'Clear Rows',
					        	handler: function() {
					        		ss2.removeAll();
					                qWin.getBottomToolbar().items.get(2).enable();
					        	}
					        }]
						})]
					}],
					bbar: [{
			        	text:'Drag and Drop to Rearrange the Order',
			        	disabled: true
			        },{xtype:'tbfill'},{
						text:'Update Question',
						iconCls:'icon-save',
						disabled: true,
						handler: function (){
							updateQuestion(q,p,qWin);
							qWin.suspendEvents();
							qWin.close();
							qWin.resumeEvents();
						}
					}],
			        listeners: {
			        	beforeclose: function(p) {
			        		if (!p.getBottomToolbar().items.get(2).disabled) {
			        			Ext.MessageBox.confirm('Unsaved Updates','The options for this question have changed. Would you like to save them?',function(btn){
			        				if (btn=="yes") {
			        					updateQuestion(q,p,qWin);
			        				}
			        			});	
			        		}	        			
			        	}
			        }
				});
				break;
			case "select":
				var ss = new Ext.data.SimpleStore({
					fields: ['display','value'],
					data: []
				});
				for (i=0;i<q.answer.length;i++) {
					ss.add(new sr({
						display: q.answer[i].display,
						format: q.answer[i].format == undefined ? false:(q.answer[i].format=="text"?true:false),
						value: q.answer[i].value
					}));
				}
				var checkColumn = new Ext.grid.CheckColumn({
			       header: 'Manual Text?',
			       dataIndex: 'format',
			       width: 55,
			       handler: function() {qWin.getBottomToolbar().items.get(1).enable();}
			    });
				var cm = new Ext.grid.ColumnModel({
					defaults:{sortable:true},
					columns: [
						{
							header:'Display Name',
							width:200,sortable: true,
							dataIndex:'display',
							editor:new Ext.form.TextField({
								allowBlank:false,
								listeners: {
									change: function() {
										qWin.getBottomToolbar().items.get(1).enable();
									}
								}
							})
						},{
							header:'Value',
							width:75,sortable: true, 
							dataIndex:'value', 
							editable: true,
							editor:new Ext.form.TextField({
								allowBlank:true,
								listeners: {
									change: function() {
										qWin.getBottomToolbar().items.get(1).enable();
									}
								}
							})
						},
						checkColumn
					]
				});
				var qWin = new Ext.Window({
					title: "Options for: "+p.title,
					width: 500,
					height: 300,
					layout:'fit',
					border: false,
					iconCls:'icon-edit',
					modal: true,
					items: [new Ext.grid.EditorGridPanel({
						border: false,
						cm:cm,
						sm: new Ext.grid.RowSelectionModel({singleSelect:true}),
						enableDragDrop: true,
						plugins: [checkColumn,new Ext.ux.dd.GridDragDropRowOrder({
					        scrollable: true
					    })],
		        		clicksToEdit: 1,
						viewConfig: {forceFit:true},
						iconCls:'icon-edit',
						store: ss
					})],
					bbar: [{xtype:'tbfill'},{
						text:'Update Question',
						iconCls:'icon-save',
						disabled: true,
						handler: function (){
							updateQuestion(q,p,qWin);
							qWin.suspendEvents();
							qWin.close();
							qWin.resumeEvents();
						}
					}],
					tbar: [{
						iconCls:'icon-add',
			            text: 'Add Option',
			            handler : function(){
			                // access the Record constructor through the grid's store
			                var grid = qWin.items.get(0);
			                var p = new sr({
			                    display: 'New Option',
			                    value: '',
			                    format: false
			                });
			                grid.stopEditing();
			                ss.insert(0, p);
			                grid.startEditing(0,0);
			                this.ownerCt.ownerCt.getBottomToolbar().items.get(1).enable();
			            }
			        },{
			        	iconCls:'icon-remove',
			        	text:'Remove Option',
			        	handler: function() {
			        		var grid = qWin.items.get(0);
			        		ss.remove(grid.getSelectionModel().getSelected());
			                this.ownerCt.ownerCt.getBottomToolbar().items.get(1).enable();
			        	}
			        },'-',{
			        	iconCls:'icon-clear',
			        	text:'Clear All',
			        	handler: function() {
			        		ss.removeAll();
			                this.ownerCt.ownerCt.getBottomToolbar().items.get(1).enable();
			        	}
			        },'->',{
			        	text:'Drag and Drop to Rearrange the Order',
			        	disabled: true
			        }],
			        listeners: {
			        	beforeclose: function(p) {
			        		if (!p.getBottomToolbar().items.get(1).disabled) {
			        			Ext.MessageBox.confirm('Unsaved Updates','The options for this question have changed. Would you like to save them?',function(btn){
			        				if (btn=="yes") {
			        					updateQuestion(q,p,qWin);
			        				}
			        			});	
			        		}	        			
			        	}
			        }
				});
				break;
			case "rate":
				var re = new RegExp("[^\\d]","g");
				var qWin = new Ext.Window({
					title: "Options for: "+p.title,
					width: 400,
					height: 175,
					layout:'fit',
					border: false,
					iconCls:'icon-edit',
					modal: true,
					items: [{
						layout:'fit',
						border: false,
						items: [new Ext.form.FormPanel({
							border: false,
							bodyStyle: 'padding: 20px',
							defaults: {
								width:200,
								height:25,
								allowBlank:false,
								xtype:'textfield',
								stripCharsRe:re,
								enableKeyEvents: true,
								listeners: {
									keyup: function(tf,e) {
										qWin.getBottomToolbar().items.get(qWin.getBottomToolbar().items.length-1).enable();
									}
								}
							},
							items: [{
								fieldLabel:'Start From',
								value: q.from
							},{
								fieldLabel:'End At',
								value: q.to
							},{
								fieldLabel:'Increment',
								value: q.increment
							}]
						})]
					}],
					bbar: [{xtype:'tbfill'},{
						text:'Update Question',
						iconCls:'icon-save',
						disabled: true,
						handler: function (){
							updateQuestion(q,p,qWin);
							qWin.suspendEvents();
							qWin.close();
							qWin.resumeEvents();
						}
					}],
					listeners: {
			        	beforeclose: function(p) {
			        		if (!p.getBottomToolbar().items.get(1).disabled) {
			        			Ext.MessageBox.confirm('Unsaved Updates','The options for this question have changed. Would you like to save them?',function(btn){
			        				if (btn=="yes") {
			        					updateQuestion(q,p,qWin);
			        				}
			        			});	
			        		}	        			
			        	}
			        }
				});
				break;
		}
		qWin.show();
	}
	
	function updateQuestion(q,p,win) {
		p.removeAll();
		switch (q.type) {
			case "select":
				q.answer = [];
				var str = win.items.get(0).getStore();
				for(var i=0;i<str.getCount();i++) {
					q.answer.push({
						display: str.getAt(i).data.display,
						value: str.getAt(i).data.value,
						format: str.getAt(i).data.format==true?"text":""
					});
				}
				break;
			case "matrix":
				//Columns
				q.answer.columns = [];
				var str = win.items.get(0).items.get(0).getStore();
				for(var i=0;i<str.getCount();i++)
					q.answer.columns.push(str.getAt(i).data.display);
				//Rows
				q.answer.options = [];
				var str = win.items.get(0).items.get(1).getStore();
				for(var i=0;i<str.getCount();i++) {
					q.answer.options.push({
						display: str.getAt(i).data.display,
						value: str.getAt(i).data.value
					});
				}
				break;
			case "rate":
				var form = win.items.get(0).items.get(0).items;
				q.from = parseInt(form.get(0).getValue());
				q.to = parseInt(form.get(1).getValue());
				q.increment = parseInt(form.get(2).getValue());
				break;
		}
		p.add(questionContents(q));
		p.data=q;
		p.doLayout();
		changeQuestions();
	}
	
	function createSubDirectory(n) {
		var tree = ctg;
		var node = new Ext.tree.TreeNode({
			text: n.dir,
			id:n.dir,
			allowDrag: true,
			allowDrop:true,
			listeners: {
				click: function(t,e) {
					tree.getTopToolbar().items.get(1).disable();
					tree.getTopToolbar().items.get(2).enable();
					tree.getTopToolbar().items.get(4).enable();
				}
			}
		});
		//Add subdirectories
		for(var y=0; y<n.sub.length; y++)
			node.appendChild(createSubDirectory(n.sub[y]));
		//Add files
		for(var y=0; y<n.files.length; y++) {
			node.appendChild(new Ext.tree.TreeNode({
				text:n.files[y].nm,
				id:n.files[y].nm,
				leaf:true,
				qtip:n.files[y].sz+' bytes',
				iconCls:'icon-script',
				data: n.files[y],
				listeners: {
					dblclick: function(node,e) {
						openSurvey(node.attributes.data.pth,node.text);
					},
					click: function(t,e) {
						tree.getTopToolbar().items.get(1).enable();
						tree.getTopToolbar().items.get(2).enable();
						tree.getTopToolbar().items.get(4).disable();
					}
				}
			}));
		}
		return node;
	}
	
	function openMap() {
		window.open(cfg.map+"?survey="+currSurvey,"Map","height=437,width=401,toolbar=no,scrollbars=no,menubar=no");
	}
	
	function deleteSurvey() {
		var node = ctg.getSelectionModel().getSelectedNode();
		var msk = new Ext.LoadMask(ctg.getEl(),{msg:'Updating...'});
		if (node.isLeaf()) {
			Ext.MessageBox.confirm('Remove Survey','Are you sure you want to <b>permanently</b> remove '+node.text+'?',function(btn){
				if (btn=="yes") {
					msk.show();
					Ext.Ajax.request({
						url:cfg.ajax,
						params:{get:'removesurvey',path:node.attributes.data.pth},
						success: function(r,o) {
							if (editor.title)
							node.remove();
							msk.hide();
						}
					});
				}
			});
		} else {
			var pth = "";
			node.bubble(function(){
				if (this != ctg.root)
					pth = "/"+this.text+pth;
			});
			if (node.hasChildNodes()) {
				Ext.MessageBox.confirm('Remove Folder','Are you sure you want to <b>permanently</b> remove '+node.text+' and <b>all</b> folders/surveys within it?',function(btn){
					if (btn=="yes") {
						msk.show();
						Ext.Ajax.request({
							url:cfg.ajax,
							params:{get:'removefolder',path:pth},
							success: function(r,o) {
								if (editor.title)
									node.remove();
								msk.hide();
							}
						});
					}
				});
			} else {
				msk.show();
				Ext.Ajax.request({
					url:cfg.ajax,
					params:{get:'removefolder',path:pth},
					success: function(r,o) {
						if (editor.title)
							node.remove();
						msk.hide();
					}
				});
			}
		}
	}
	
	function copySurvey() {
		var node = ctg.getSelectionModel().getSelectedNode();
		var copyWin = new Ext.Window({
			title: 'Copy '+node.text,
			width: 400,
			height: 125,
			modal:true,
			layout:'fit',
			closeAction:'close',
			items: [new Ext.form.FormPanel({
				border: false,
				bodyStyle:'padding: 15px',
				items: [{
					width: 250,
					xtype:'textfield',
					fieldLabel: 'Save Survey As',
					value: 'Copy of '+node.text,
					allowBlank:false,
					emptyText:'Survey Name...',
					selectOnFocus:true
				}]
			})],
			bbar: new Ext.Toolbar({
				items:['->',{
					text:'Finish',
					iconCls:'icon-finish',
					handler: function(){
						this.ownerCt.disable();
						var copied = createCopy(node,this.ownerCt.ownerCt.items.get(0).items.get(0).getValue());
						this.ownerCt.ownerCt.hide();
					}
				}]
			})
		});
		copyWin.show();
	}
	
	function createCopy(node,name) {
		var data = node.attributes.data;
		Ext.Ajax.request({
			url:cfg.ajax,
			params:{get:'copysurvey',path:node.attributes.data.pth,name:name},
			success: function(r,o) {
				var path = Ext.decode(r.responseText).path;
				data.pth = path;
				node.parentNode.appendChild(new Ext.tree.TreeNode({
					leaf:true,
					text:name,
					iconCls:'icon-script',
					qtip:node.attributes.data.sz+' bytes',
					data:data,
					listeners: {
						dblclick: function(node,e) {
							openSurvey(node.attributes.data.pth,node.text);
						},
						click: function(t,e) {
							this.getOwnerTree().getTopToolbar().items.get(1).enable();
							this.getOwnerTree().getTopToolbar().items.get(2).enable();
							this.getOwnerTree().getTopToolbar().items.get(4).disable();
						}
					}
				}));
			}
		});
		return true;
	}
	
	function addDirectory() {
		var node = ctg.getSelectionModel().getSelectedNode();
		var dirWin = new Ext.Window({
			title: 'New Folder',
			width: 400,
			height: 125,
			modal:true,
			layout:'fit',
			closeAction:'close',
			items: [new Ext.form.FormPanel({
				border: false,
				bodyStyle:'padding: 15px',
				items: [{
					width: 250,
					xtype:'textfield',
					fieldLabel: 'Name',
					allowBlank:false,
					emptyText:'Folder Name...',
					selectOnFocus:true
				}]
			})],
			bbar: new Ext.Toolbar({
				items:['->',{
					text:'Finish',
					iconCls:'icon-finish',
					handler: function(){
						this.ownerCt.disable();
						var done = createFolder(node,this.ownerCt.ownerCt.items.get(0).items.get(0).getValue());
						this.ownerCt.ownerCt.hide();
					}
				}]
			})
		});
		dirWin.show();
	}
	
	function createFolder(node,name) {
		var pth = "";
		node.bubble(function(){
			if (this != ctg.root)
				pth = "/"+this.text+pth;
		});
		Ext.Ajax.request({
			url:cfg.ajax,
			params:{get:'createfolder',path:pth+"/"+name},
			success: function(r,o) {
				node.appendChild(new Ext.tree.TreeNode({
					text: name,
					allowDrag:true,
					allowDrop:true,
					listeners: {
						click: function(t,e) {
							ctg.getTopToolbar().items.get(1).disable();
							ctg.getTopToolbar().items.get(2).enable();
							ctg.getTopToolbar().items.get(4).enable();
						}
					}
				}));
			}
		});
		return true;
	}
	
	function createSurvey() {
		var node = ctg.getSelectionModel().getSelectedNode();
		if (node == null)
			node = ctg.root;
		if (node.isLeaf())
			node = node.parentNode;
		var newSurveyWin = new Ext.Window({
			title:'New Survey',
			iconCls:'icon-script-add',
			width: 500,
			height: 250,
			layout:'fit',
			modal:true,
			closeAction:'close',
			items:[new Ext.form.FormPanel({
				bodyStyle:'padding:20px',
				border: false,
				defaults:{width:300},
				items:[{
					xtype:'textfield',
					fieldLabel:'Survey Name',
					allowBlank:false,
					enableKeyEvents:true,
					listeners:{
						keyup: function(tf,e) {
							if (tf.isValid())
								tf.ownerCt.getBottomToolbar().items.get(1).enable();
							else
								tf.ownerCt.getBottomToolbar().items.get(1).disable();
						}
					}
				},{
					xtype:'textarea',
					fieldLabel:'Description',
					height: 100
				}],
				bbar: new Ext.Toolbar({
					items:['->',{
						text:'Complete',
						iconCls:'icon-finish',
						disabled:true,
						handler:function(){
							var obj = {};
							var pth = "";
							node.bubble(function(){
								if (this != ctg.root)
									pth = "/"+this.text+pth;
							});
							obj.nm = newSurveyWin.items.get(0).items.get(0).getValue();
							obj.sz=0;
							Ext.Ajax.request({
								url:cfg.ajax,
								params:{get:'createsurvey',name:obj.nm,path:pth,dsc:newSurveyWin.items.get(0).items.get(1).getValue()},
								success: function(r,o) {
									obj.pth = Ext.decode(r.responseText).path;
									node.appendChild(new Ext.tree.TreeNode({
										text:obj.nm,
										id:obj.nm,
										leaf:true,
										qtip:'0 bytes',
										iconCls:'icon-script',
										data: obj,
										listeners: {
											dblclick: function(n,e) {
												openSurvey(n.attributes.data.pth,n.text);
											},
											click: function(t,e) {
												ctg.getTopToolbar().items.get(1).enable();
												ctg.getTopToolbar().items.get(2).enable();
												ctg.getTopToolbar().items.get(4).disable();
											},
											contextmenu: function(node,e) {
												node.select();
												var ctx = new Ext.menu.Menu({
													items:[{
														text:'Edit Survey',
														iconCls:'icon-script',
														handler: function() {openSurvey(node.attributes.data.pth,node.text);}
													},{
														text:'Copy',
														iconCls:'icon-copy',
														handler: copySurvey
													},{
														text:'Delete',
														iconCls:'icon-remove',
														handler: deleteSurvey
													}]
												});
												ctx.showAt(e.getXY());
											}
										}
									}));
									newSurveyWin.close();
								}
							});
						}
					}]
				})
			})]
		});
		newSurveyWin.show();
	}
	
	function changeQuestions() {
		var qtab = editor.items.get(0).items.get(0);
		if (editor.title.substring(0,1)!="*")
			editor.setTitle("*"+editor.title);
		qtab.getTopToolbar().items.get(0).enable();
		acl.getTopToolbar().items.get(0).enable();
		processing.getTopToolbar().items.get(0).enable();
	}
	
	function stripCode(src,tag){
		var re=new RegExp("<"+tag+".*\/"+tag+"\>","g");
		var out=src.replace(re,"");
		return out;
	}
	
	function stripFunctions(src,tag){
		var list=['remove','getTimezone','dateFormat','getElapsed','getDayOfYear','getWeekOfYear','getGMTOffset','isLeapYear','isLeapYear','isDST'];
		var out = src;
		for (var i=0;i<list.length;i++)
			out = stripCode(out,list[i]);
		return out;
	}
	
	function saveForm() {
		var msk = new Ext.LoadMask(Ext.getBody(),{msg:'Saving Survey. Please Wait.'});
		
		var qa = editor.items.get(0).items.get(0).items.get(0).items.get(0).items;
		var ptab = editor.items.get(0).items.get(1).items.get(0).items;
		var stab = editor.items.get(0).items.get(2).items.get(0).items;
		var q = [];
		var out = {};
		
		msk.show();
		
		//Get Questions
		for(var i=0;i<=qa.length;i++) {
			if (i!=qa.length) {
				qa.get(i).data.text = qa.get(i).getTopToolbar().items.get(1).getValue();
				qa.get(i).data.required = qa.get(i).getTopToolbar().items.get(4).getValue();
				q.push(qa.get(i).data);
			}
		}
		out.qa = {};
		out.qa.q = q;
		
		//Add basic properties
		var props = {};
		props.url = ptab.get(0).getRawValue();
		props.action = ptab.get(1).getRawValue();
		props.alert = ptab.get(2).getRawValue();
		props.start = ptab.get(4).getRawValue();
		props.end = ptab.get(5).getRawValue();
		props.priv = stab.get(0).getValue();
		props.password = stab.get(1).getRawValue();
		props.file = currSurvey;
		props.title = storeProperty.getAt(0).data.value;
		props.dsc = storeProperty.getAt(1).data.value;
		out.prop = props;
		
		//Add security
		out.acl = {};
		out.acl.usr = [];
		for(var i=0;i<storeACL.getCount();i++)
			out.acl.usr[i]=storeACL.getAt(i).data.display;
		//Clear unnecessary functions that ExtJS Created
		var xmlout = stripCode(JSON2XML(out),"remove");
		for(var i=0;i<=qa.length;i++) {
			var re = RegExp("<"+i+">","g");
			var re2 = RegExp("<\/"+i+">","g");
			xmlout = xmlout.replace(re,"<question>");
			xmlout = xmlout.replace(re2,"</question>");
		}
		
		xmlout = xmlout.replace(/<\?xml version\=\"1\.0\" encoding=\"UTF\-8\"\?\>/g,'');
		//xmlout = xmlout.replace(/\> </g,'');
		
		Ext.Ajax.request({
			url:cfg.ajax,
			params:{get:'savesurvey',survey:'<survey>'+xmlout+'</survey>'},
			success: function(r,o) {
				if (editor.title.substring(0,1)=="*")
					editor.setTitle(editor.title.substring(1,editor.title.length));
				editor.items.get(0).items.get(0).getTopToolbar().items.get(0).disable();
				acl.getTopToolbar().items.get(0).disable();
				processing.getTopToolbar().items.get(0).disable();
				msk.hide();
			}
		});
	}
});