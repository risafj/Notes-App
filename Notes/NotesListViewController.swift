import UIKit

class NotesListViewController: UITableViewController {
    var notes: [Note] = []
    
    @IBAction func createNote() {
        let _ = NoteManager.shared.create()
        reload()
    }
    
    func reload() {
        notes = NoteManager.shared.getNotes()
        tableView.reloadData()
    }

    // viewDidLoad is only called once, when this controller is created.
    // viewWillAppear is called every time they come to this screen.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    // Necessary for TableView.
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    // Necessary for TableView.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }

    // Necessary for creating each cell in TableView (called for each cell).
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell", for: indexPath)
        cell.textLabel?.text = notes[indexPath.row].content
        // This is for passing the row number to the swipe function.
        cell.textLabel?.tag = indexPath.row

        cell.textLabel?.isUserInteractionEnabled = true
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.labelSwipedLeft(sender:)))
        swipeLeft.direction = .left
        cell.textLabel?.addGestureRecognizer(swipeLeft)

        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NoteSegue",
                let destination = segue.destination as? NoteViewController,
                let index = tableView.indexPathForSelectedRow?.row {
            destination.note = notes[index]
        }
    }

    @objc func labelSwipedLeft(sender: UISwipeGestureRecognizer) {
        deleteNote(noteRow: sender.view!.tag)
    }

    func deleteNote(noteRow: Int) {
        let ac = UIAlertController(title: "Delete this note?", message: notes[noteRow].content, preferredStyle: .alert)

        let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: .default, handler: {
            (action: UIAlertAction!) -> Void in
            NoteManager.shared.delete(note: self.notes[noteRow])
            self.reload()
        })
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)

        ac.addAction(defaultAction)
        ac.addAction(cancelAction)

        present(ac, animated: true)
    }
}
