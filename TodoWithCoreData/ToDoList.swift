//
//  ToDoList.swift
//  TodoWithCoreData
//
//  Created by chunwei xu on 2023/5/31.
//

import SwiftUI
import CoreData
 

struct ToDoList: View {
    
    @Environment(\.managedObjectContext) private var viewContext //context on main thread
    
    let backgroundViewContext = PersistenceController.shared.container.newBackgroundContext() //context on background thread
 
    @FetchRequest(
        entity: ToDoItem.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ToDoItem.order, ascending: true)],
        predicate: nil,
        animation: .default
    ) private var items: FetchedResults<ToDoItem>
    
    //or seperate them -- it's all about manipulating FetchRequest and FetchResults
//    var fetchRequest = FetchRequest<ToDoItem>(
//        entity: ToDoItem.entity(),
//        sortDescriptors: [NSSortDescriptor(keyPath: \ToDoItem.order, ascending: true)],
//        predicate: nil,
//        animation: .default
//    )
//
//    var items: FetchedResults<ToDoItem> {
//        fetchRequest.wrappedValue
//    }
 
    private let colorMapper: [Int: Color] = [0: Color.green, 1: Color.yellow, 2: Color.red]
    
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var showSheet: Bool = false
    @State private var newTodoName: String = ""
    @State private var newTodoFlag: Int16 = 0
    @State private var selection = Set<ToDoItem>()
    @State private var searchText: String = ""
    
     
    var body: some View {
        NavigationView {
            VStack {
                
                TextField("Search", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: searchText) { newValue in
                        //edit items's nsPredicate to apply FetchRequest filter
                        items.nsPredicate = newValue.isEmpty ? nil : NSPredicate(format: "name CONTAINS[c] %@", newValue)
                    }
                
                if items.count == 0 {
                    Text("No data")
                } else {
                
                    List(selection: $selection) {
                        ForEach(items) { item in
                            
                            HStack {
                                Text(item.name ?? "oooops")
                                Spacer()
                                Circle()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(colorMapper[Int(item.colorflag)])
                            }
                            .padding()
                        }
                        .onMove(perform: moveItems)
                        .onDelete(perform: deleteItems)
                    }
                }
                Spacer()
            }
            .navigationTitle("TodoList")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
               
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Alert"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showSheet) {
                VStack {
                    HStack {
                        Spacer()
                        Button("dismiss", action: {
                            showSheet.toggle()
                        })
                    }
                    .padding()
                    
                    Form {
                        
                        Section(header: Text("to do")) {
                            TextField("Todo Topic", text: $newTodoName)
                        }
                        Section(header: Text("flag")) {
                            Picker(selection: $newTodoFlag, label: Text("")) {
                                                        Text("Low").tag(Int16(0))
                                                        Text("Medium").tag(Int16(1))
                                                        Text("High").tag(Int16(2))
                                                    }
                                                    .pickerStyle(SegmentedPickerStyle())
                        }
                        Section {
                            
                            Button(action: {
                                addItemInBackground(name: newTodoName, colorflag: newTodoFlag)
                                newTodoName = ""
                                showSheet.toggle()
                                
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Save")
                                    Spacer()
                                }
                            }
                        }
                    }
                    Spacer()
                }
                 
            }
            
            
        }
    }
    
    private var addButton: some View {
        Button(action: {
            
            showSheet = true
            
        }) {
            Image(systemName: "plus.circle.fill")
                .imageScale(.large)
                .padding()
        }
    }
   
}

// functions to CRUD database
extension ToDoList {
    
    //  on main threads
   
    private func addItem(name: String = "ToDo", colorflag:Int16 = 0) {
        withAnimation {
            let newItem = ToDoItem(context: viewContext)
            newItem.name = name
            newItem.colorflag = colorflag

            do {
                try viewContext.saveIfNeed()
            } catch {
                handleError(error: error)
                viewContext.rollback()
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.saveIfNeed()

            } catch {
                handleError(error: error)
                viewContext.rollback()
            }
        }
    }
    
    private func moveItems(from source: IndexSet, to destination: Int) {
        withAnimation {
            var revisedItems: [ToDoItem] = items.map { $0 }
            revisedItems.move(fromOffsets: source, toOffset: destination)
            for reverseIndex in stride(from: revisedItems.count - 1, through: 0, by: -1) {
                revisedItems[reverseIndex].order = Int16(reverseIndex)
            }
            
            do {
                try viewContext.saveIfNeed()
            } catch {
                handleError(error: error)
                viewContext.rollback()
            }
        }
    }
    
    // when data loads tons, crud on main thread would be slow and block UI which makes app less responsive.
    // consider use a background managed object context.
    private func addItemInBackground(name: String = "ToDo", colorflag:Int16 = 0) {
        
        backgroundViewContext.perform {

            let newItem = ToDoItem(context: backgroundViewContext)
            newItem.name = name
            newItem.colorflag = colorflag

            do {
                try backgroundViewContext.saveIfNeed()
            } catch {
                handleError(error: error)
                backgroundViewContext.rollback()
            }
        }
        
        // or, we can just use persistentContainer.performBackgroundTask if we don't want to keep a backgroundViewContext
//        PersistenceController.shared.container.performBackgroundTask { bgViewContext in
//            // ...
//        }
    }
    
    // and so to other context changes ...
    
//MARK - unused
    
    private func customFetch(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) {
        
        let fetchRequest : NSFetchRequest<ToDoItem> = ToDoItem.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        do {
            _ = try viewContext.fetch(fetchRequest)
        }
        catch {
            
        }
    }
    
    private func batchDeleteRequest() {
        
        //setup fetchRequest to define what to be deleted, here to delete all todos
        let fetchRequest : NSFetchRequest<NSFetchRequestResult>
        fetchRequest = NSFetchRequest(entityName: "ToDoItem")
        //deleteRequest based on fetchRequest
        let batchDeleteRequest: NSBatchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        do {
            //try delete
            let batchDelete = try viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
            
            guard let deleteResult = batchDelete?.result as? [NSManagedObjectID] else {
                return
            }
                
            let deletedObjects: [AnyHashable: Any] = [ NSDeletedObjectsKey: deleteResult ]
            
            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: deletedObjects,
                into: [viewContext]
            )
        }
        catch {
            
        }
    }
}
 
extension ToDoList {
    
    func handleError(error: Error) {
        // show alert and roll back
        let nsError = error as NSError
        alertMessage = nsError.localizedDescription
        showAlert = true
    }
}
 
struct ToDoList_Previews: PreviewProvider {
    static var previews: some View {
        ToDoList()
    }
}


